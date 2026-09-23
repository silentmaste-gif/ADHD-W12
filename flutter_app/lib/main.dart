import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    providerWeb: kIsWeb ? WebDebugProvider() : null,
    providerAndroid: const AndroidDebugProvider(),
    providerWindows: const WindowsDebugProvider(
      debugToken: String.fromEnvironment('APP_CHECK_DEBUG_TOKEN'),
    ),
  );

  final provider = AppProvider();
  NotificationService.onNotificationTap = provider.openNotificationPrompt;
  final launchPrompt = await NotificationService.initialize();
  await provider.init(); // Load accessibility settings from storage
  if (provider.currentUser != null) {
    await NotificationService.scheduleDailyReminders();
  }
  if (launchPrompt != null) provider.openNotificationPrompt(launchPrompt);

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const AidhdApp(),
    ),
  );
}
