import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettings {
  final bool isMuted;

  NotificationSettings({this.isMuted = false});

  NotificationSettings copyWith({bool? isMuted}) {
    return NotificationSettings(isMuted: isMuted ?? this.isMuted);
  }
}

class NotificationNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    return NotificationSettings();
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void setMute(bool value) {
    state = state.copyWith(isMuted: value);
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationSettings>(() {
  return NotificationNotifier();
});
