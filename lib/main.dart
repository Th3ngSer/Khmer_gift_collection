import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://liqraghkzfjsgcyfgpdd.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpcXJhZ2hremZqc2djeWZncGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNTAwMjgsImV4cCI6MjA5NTYyNjAyOH0.sJJW-x5mOC0OII90gClR7zkzBvMnFp8GesTWr867QSE', 
  );

  runApp(
    const ProviderScope(
      child: KhmerGiftApp(),
    ),
  );
}

class KhmerGiftApp extends ConsumerWidget {
  const KhmerGiftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Khmer Gift Collection',
      debugShowCheckedModeBanner: false,
      locale: locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: goRouter,
    );
  }
}
