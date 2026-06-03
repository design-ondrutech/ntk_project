import 'package:equatable/equatable.dart';

abstract class CommunityPollsEvent extends Equatable {
  const CommunityPollsEvent();

  @override
  List<Object?> get props => [];
}

class FetchPollsEvent extends CommunityPollsEvent {
  final int? communityId;
  final int? locationId;
  const FetchPollsEvent({this.communityId, this.locationId});
  @override
  List<Object?> get props => [communityId, locationId];
}

class CreatePollEvent extends CommunityPollsEvent {
  final String question;
  final List<String> options;
  final int durationDays;
  final int locationId;
  final int? communityId;

  const CreatePollEvent({
    required this.question,
    required this.options,
    required this.durationDays,
    required this.locationId,
    this.communityId,
  });

  @override
  List<Object?> get props => [
    question,
    options,
    durationDays,
    locationId,
    communityId,
  ];
}

class VoteInPollEvent extends CommunityPollsEvent {
  final int pollId;
  final int optionId;
  const VoteInPollEvent({required this.pollId, required this.optionId});
  @override
  List<Object?> get props => [pollId, optionId];
}

class ClearPollsMessage extends CommunityPollsEvent {
  const ClearPollsMessage();
}

class ClearPollsError extends CommunityPollsEvent {
  const ClearPollsError();
}
