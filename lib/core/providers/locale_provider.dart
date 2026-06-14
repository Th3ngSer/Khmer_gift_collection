import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Using Notifier which is the preferred way in modern Riverpod
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en', 'US');
  }

  void setLocale(Locale locale) {
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LanguageModel {
  final String name;
  final String code;
  final String flag;

  LanguageModel({required this.name, required this.code, required this.flag});
}

final languages = [
  LanguageModel(name: 'English', code: 'en', flag: '🇺🇸'),
  LanguageModel(name: 'ភាសាខ្មែរ', code: 'km', flag: '🇰🇭'),
  LanguageModel(name: '中文', code: 'zh', flag: '🇨🇳'),
];
