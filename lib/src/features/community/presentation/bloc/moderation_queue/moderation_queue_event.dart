import 'package:equatable/equatable.dart';

abstract class ModerationQueueEvent extends Equatable {
  const ModerationQueueEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportedPosts extends ModerationQueueEvent {
  final int? locationId;
  const LoadReportedPosts({this.locationId});

  @override
  List<Object?> get props => [locationId];
}

class ModeratePost extends ModerationQueueEvent {
  final int postId;
  final String action; // 'KEEP', 'WARNING', 'DELETE'
  final String? warningMessage;

  const ModeratePost({
    required this.postId,
    required this.action,
    this.warningMessage,
  });

  @override
  List<Object?> get props => [postId, action, warningMessage];
}

class ClearModerationMessage extends ModerationQueueEvent {}
class ClearModerationError extends ModerationQueueEvent {}

class RemovePostFromQueue extends ModerationQueueEvent {
  final int postId;
  const RemovePostFromQueue({required this.postId});
  
  @override
  List<Object?> get props => [postId];
}
