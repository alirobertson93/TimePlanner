import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/display_title_service.dart';

/// Provider for the DisplayTitleService
/// 
/// This service computes display titles for activities that may not have
/// explicit names, deriving titles from associated entities (people,
/// locations, categories).
final displayTitleServiceProvider = Provider<DisplayTitleService>((ref) {
  return const DisplayTitleService();
});
