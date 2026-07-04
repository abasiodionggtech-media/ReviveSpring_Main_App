import 'dart:convert';
import 'dart:io';

import '../data/app_data.dart';
import '../models/chat_message.dart';

class AiService {
  AiService({this.baseUrl = 'https://revivespring.onrender.com/api'});

  final String baseUrl;

  String defaultSessionForEmail(String email) => 'rs-user-${email.trim().toLowerCase()}';

  Future<List<Map<String, dynamic>>> getSessions({
    required String userEmail,
    String? authToken,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse('$baseUrl/ai/sessions?userEmail=${Uri.encodeQueryComponent(userEmail)}');
      final req = await client.getUrl(uri);
      if (authToken != null && authToken.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }
      final res = await req.close();
      final text = await utf8.decodeStream(res);
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final data = jsonDecode(text);
      final list = data is Map && data['sessions'] is List ? data['sessions'] as List : const [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  Future<List<ChatMessage>> getHistory({
    required String sessionId,
    required String userEmail,
    String? authToken,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.parse('$baseUrl/ai/history?sessionId=${Uri.encodeQueryComponent(sessionId)}');
      final req = await client.getUrl(uri);
      if (authToken != null && authToken.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }
      final res = await req.close();
      final text = await utf8.decodeStream(res);
      if (res.statusCode < 200 || res.statusCode >= 300) return const [];
      final data = jsonDecode(text);
      final list = data is Map && data['messages'] is List ? data['messages'] as List : const [];
      return list
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((item) => item.content.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  Future<String> sendMessage({
    required String message,
    required String language,
    required List<ChatMessage> history,
    required String sessionId,
    String? userEmail,
    String? authToken,
    String? unlockToken,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse('$baseUrl/ai/chat'));
      req.headers.contentType = ContentType.json;
      if (authToken != null && authToken.isNotEmpty) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      }
      req.write(jsonEncode({
        'message': message,
        'sessionId': sessionId,
        'language': language,
        'userEmail': userEmail,
        'unlockToken': unlockToken,
        'history': history.take(10).map((item) => item.toJson()).toList(),
      }));
      final res = await req.close();
      final text = await utf8.decodeStream(res);
      if (res.statusCode < 200 || res.statusCode >= 300) return fallbackAiPrayer(message);
      final data = jsonDecode(text);
      return (data['reply'] ?? fallbackAiPrayer(message)).toString();
    } catch (_) {
      return fallbackAiPrayer(message);
    } finally {
      client.close(force: true);
    }
  }
}
