import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Downloads the onboarding intro video in the background (kicked off the
/// moment onboarding starts, so it has the whole onboarding flow to finish
/// before the user reaches the video screen), caches it to a temp file, and
/// deletes that file again once the user has watched it.
class IntroVideoService {
  IntroVideoService._();
  static final IntroVideoService instance = IntroVideoService._();

  static const _fileName = 'revivespring_intro_video.mp4';

  Future<void>? _downloadFuture;
  File? _cachedFile;
  bool _failed = false;

  /// Call this once, right when onboarding begins. Safe to call more than
  /// once — later calls just return the same in-flight download.
  Future<void> startBackgroundDownload(String videoUrl) {
    return _downloadFuture ??= _download(videoUrl);
  }

  Future<void> _download(String videoUrl) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$_fileName');

      // Already cached from a previous attempt this session — nothing to do.
      if (await file.exists() && await file.length() > 0) {
        _cachedFile = file;
        return;
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(videoUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        _failed = true;
        client.close(force: true);
        return;
      }

      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
      client.close();

      _cachedFile = file;
    } catch (_) {
      _failed = true;
    }
  }

  /// Waits for the background download to finish, up to [timeout]. Returns
  /// the local file if it's ready, or null if it timed out or failed — the
  /// caller can fall back to streaming straight from [videoUrl] instead.
  Future<File?> waitUntilReady({Duration timeout = const Duration(seconds: 8)}) async {
    if (_cachedFile != null) return _cachedFile;
    if (_failed) return null;
    final future = _downloadFuture;
    if (future == null) return null;
    try {
      await future.timeout(timeout);
    } catch (_) {
      // Still downloading, or failed — either way, caller decides what to do.
    }
    return _cachedFile;
  }

  bool get isReady => _cachedFile != null;
  bool get hasFailed => _failed;

  /// Deletes the cached video file — call this once the user has finished
  /// watching it, so it doesn't sit on their device afterward.
  Future<void> deleteCachedFile() async {
    try {
      final file = _cachedFile;
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Non-critical — worst case, it gets cleared with the OS's normal
      // temp-directory cleanup later.
    } finally {
      _cachedFile = null;
      _downloadFuture = null;
      _failed = false;
    }
  }
}
