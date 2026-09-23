import 'dart:convert';

import 'package:http/http.dart' as http;
import 'ai_provider_service.dart';

class AiException implements Exception {
  final String message;
  final bool keyProblem;

  const AiException(this.message, {this.keyProblem = false});

  @override
  String toString() => message;
}

class AiService {
  Future<String> sendMessage({
    required AiProviderConfig config,
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    if (config.provider == AiProvider.gemini) {
      return _sendGemini(config, systemPrompt, history, message);
    }
    return _sendOpenAiCompatible(config, systemPrompt, history, message);
  }

  Future<String> _sendGemini(
    AiProviderConfig config,
    String systemPrompt,
    List<Map<String, String>> history,
    String message,
  ) async {
    final endpoint = '${config.endpoint}/${config.model}:generateContent';
    final contents = [
      ...history.map((item) => {
            'role': item['role']!,
            'parts': jsonEncode([
              {'text': item['text']!}
            ]),
          }),
      {
        'role': 'user',
        'parts': jsonEncode([
          {'text': message}
        ]),
      },
    ];

    final response = await http.post(
      Uri.parse('$endpoint?key=${Uri.encodeQueryComponent(config.apiKey)}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': contents
            .map((item) => {
                  'role': item['role'],
                  'parts': jsonDecode(item['parts']!),
                })
            .toList(),
        'generationConfig': {
          'temperature': 0.6,
          'maxOutputTokens': 900,
        },
      }),
    );

    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiException(_errorMessage(response.statusCode, data),
          keyProblem: response.statusCode == 401 ||
              response.statusCode == 403 ||
              response.statusCode == 429);
    }

    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AiException('Gemini did not return a response.');
    }
    final parts = candidates.first['content']?['parts'];
    if (parts is! List || parts.isEmpty || parts.first['text'] is! String) {
      throw const AiException('Gemini returned an empty response.');
    }
    return (parts.first['text'] as String).trim();
  }

  Future<String> _sendOpenAiCompatible(
    AiProviderConfig config,
    String systemPrompt,
    List<Map<String, String>> history,
    String message,
  ) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map((item) => {
            'role': item['role'] == 'model' ? 'assistant' : 'user',
            'content': item['text']!,
          }),
      {'role': 'user', 'content': message},
    ];
    final requestBody = <String, dynamic>{
      'model': config.model,
      'messages': messages,
      if (config.model.startsWith('gpt-5'))
        'max_completion_tokens': 900
      else ...{
        'temperature': 0.6,
        'max_tokens': 900,
      },
    };
    final response = await http.post(
      Uri.parse(config.endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode(requestBody),
    );
    final data = _decode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiException(_errorMessage(response.statusCode, data),
          keyProblem: response.statusCode == 401 ||
              response.statusCode == 403 ||
              response.statusCode == 429);
    }
    final content = data['choices']?[0]?['message']?['content'];
    final text = _readOpenAiContent(content);
    if (text == null || text.trim().isEmpty) {
      throw const AiException('The selected AI returned an empty response.');
    }
    return text.trim();
  }

  String? _readOpenAiContent(dynamic content) {
    if (content is String) return content;
    if (content is List) {
      final parts = content
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .toList();
      if (parts.isNotEmpty) return parts.join();
    }
    return null;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _errorMessage(int statusCode, Map<String, dynamic> data) {
    final message = data['error']?['message'];
    if (message is String && message.isNotEmpty) return message;
    switch (statusCode) {
      case 429:
        return 'This AI provider has reached its usage limit.';
      case 400:
      case 401:
      case 403:
        return 'This AI provider key was rejected. Check it and try again.';
      default:
        return 'The selected AI provider is temporarily unavailable. Please try again.';
    }
  }
}
