import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';

/// Provider for the application database
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
