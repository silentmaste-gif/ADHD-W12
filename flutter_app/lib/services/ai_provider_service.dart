import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { gemini, openAi }

class AiProviderConfig {
  final AiProvider provider;
  final String apiKey;
  final String model;
  final String endpoint;

  const AiProviderConfig({
    required this.provider,
    required this.apiKey,
    required this.model,
    required this.endpoint,
  });

  String get providerLabel {
    switch (provider) {
      case AiProvider.gemini:
        return 'Google Gemini';
      case AiProvider.openAi:
        return 'OpenAI';
    }
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'model': model,
        'endpoint': endpoint,
      };

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String?;
    final provider = AiProvider.values.firstWhere(
      (item) => item.name == providerName,
      orElse: () => AiProvider.gemini,
    );
    return AiProviderConfig(
      provider: provider,
      apiKey: json['apiKey'] as String? ?? '',
      model: models(provider).contains(json['model'])
          ? json['model'] as String
          : defaultModel(provider),
      endpoint: defaultEndpoint(provider),
    );
  }

  static String defaultModel(AiProvider provider) {
    switch (provider) {
      case AiProvider.gemini:
        return 'gemini-3.1-flash-lite-preview';
      case AiProvider.openAi:
        return 'gpt-5-mini';
    }
  }

  static List<String> models(AiProvider provider) {
    switch (provider) {
      case AiProvider.gemini:
        return [
          'gemini-3.1-flash-lite-preview',
          'gemini-3-flash-preview',
          'gemini-3.1-pro-preview',
        ];
      case AiProvider.openAi:
        return [
          'gpt-5-mini',
          'gpt-5',
          'gpt-4.1',
        ];
    }
  }

  static String defaultEndpoint(AiProvider provider) {
    switch (provider) {
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta/models';
      case AiProvider.openAi:
        return 'https://api.openai.com/v1/chat/completions';
    }
  }
}

class AiProviderService {
  static const _configPrefix = 'aidhd_ai_config_';
  static const _checkInPrefix = 'aidhd_check_in_';

  Future<AiProviderConfig?> getConfig(String userId) async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final remote = document.data()?['aiProviderConfig'];
      if (remote is Map) {
        final config =
            AiProviderConfig.fromJson(Map<String, dynamic>.from(remote));
        if (config.apiKey.trim().isNotEmpty) {
          await _saveLocal(userId, config);
          return config;
        }
      }
    } on FirebaseException {
      // Fall back to the local cache when the network is unavailable.
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_configPrefix$userId');
    if (raw == null) return null;
    try {
      final config =
          AiProviderConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return config.apiKey.trim().isEmpty ? null : config;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveConfig(String userId, AiProviderConfig config) async {
    await _saveLocal(userId, config);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {'aiProviderConfig': config.toJson()},
        SetOptions(merge: true),
      );
    } on FirebaseException {
      // The local cache keeps the provider usable until Firestore recovers.
    }
  }

  Future<void> _saveLocal(String userId, AiProviderConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_configPrefix$userId', jsonEncode(config.toJson()));
  }

  Future<bool> needsDailyCheckIn(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return prefs.getString('$_checkInPrefix$userId') != today;
  }

  Future<void> markDailyCheckIn(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('$_checkInPrefix$userId', today);
  }
}
