import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app/app.dart';
import 'domain/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for scheduled notifications
  tz.initializeTimeZones();
  
  // Initialize the notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
