import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Downloads the Verse of the Moment background videos once, stores them in
/// the app's support directory (which persists across launches, unlike the
/// temp dir the OS can clear), and hands back local file paths.
///
/// After the first successful download the videos play instantly and work
/// with no internet connection at all. Nothing here ever throws — if a
/// download fails the caller just falls back to streaming, so a bad network
/// degrades playback rather than breaking the screen.
class VideoCacheService {
  VideoCacheService._();
  static final VideoCacheService instance = VideoCacheService._();

  static const _folderName = 'verse_backgrounds';

  Directory? _cacheDir;
  final Map<String, File> _cached = {};
  final Map<String, Future<File?>> _inFlight = {};
  bool _warmed = false;

  Future<Directory> _dir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  /// Turns a remote URL into the local filename we cache it under.
  String _fileNameFor(String url) {
    final name = Uri.parse(url).pathSegments.last;
    // Guard against a URL with no usable filename.
    return name.isEmpty ? 'bg-${url.hashCode}.mp4' : name;
  }

  /// Returns the already-cached file for [url], or null if it isn't cached
  /// yet. Cheap, synchronous-ish check used at playback time.
  Future<File?> cachedFileFor(String url) async {
    final existing = _cached[url];
    if (existing != null && await existing.exists()) return existing;

    try {
      final dir = await _dir();
      final file = File('${dir.path}/${_fileNameFor(url)}');
      if (await file.exists() && await file.length() > 0) {
        _cached[url] = file;
        return file;
      }
    } catch (_) {
      // Cache unavailable — caller falls back to streaming.
    }
    return null;
  }

  /// Downloads [url] into the cache if it isn't there already. Safe to call
  /// repeatedly; concurrent calls for the same url share one download.
  Future<File?> download(String url) {
    final existing = _inFlight[url];
    if (existing != null) return existing;

    final future = _download(url).whenComplete(() => _inFlight.remove(url));
    _inFlight[url] = future;
    return future;
  }

  Future<File?> _download(String url) async {
    final already = await cachedFileFor(url);
    if (already != null) return already;

    HttpClient? client;
    File? partial;
    try {
      final dir = await _dir();
      final file = File('${dir.path}/${_fileNameFor(url)}');
      // Download to a .part file first, then rename — so an interrupted
      // download can never leave a truncated file that looks "cached" and
      // then fails to play.
      partial = File('${file.path}.part');

      client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return null;

      final sink = partial.openWrite();
      await response.pipe(sink);
      await sink.close();

      if (await partial.length() == 0) {
        await partial.delete();
        return null;
      }

      await partial.rename(file.path);
      _cached[url] = file;
      return file;
    } catch (_) {
      try {
        if (partial != null && await partial.exists()) await partial.delete();
      } catch (_) {}
      return null;
    } finally {
      client?.close();
    }
  }

  /// Downloads every background video in the background, one at a time so we
  /// don't saturate the connection. Call once after sign-in; later calls are
  /// no-ops. Failures are ignored — playback falls back to streaming.
  Future<void> warmCache(List<String> urls) async {
    if (_warmed || urls.isEmpty) return;
    _warmed = true;
    for (final url in urls) {
      await download(url);
    }
  }

  /// True once at least one video is available offline.
  Future<bool> hasAnyCached(List<String> urls) async {
    for (final url in urls) {
      if (await cachedFileFor(url) != null) return true;
    }
    return false;
  }
}
