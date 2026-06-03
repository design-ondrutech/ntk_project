import 'package:equatable/equatable.dart';

abstract class NotificationSettingsEvent extends Equatable {
  const NotificationSettingsEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotificationSettings extends NotificationSettingsEvent {}

class ToggleNotificationSetting extends NotificationSettingsEvent {
  final String key;
  final bool value;
  const ToggleNotificationSetting(this.key, this.value);

  @override
  List<Object?> get props => [key, value];
}
