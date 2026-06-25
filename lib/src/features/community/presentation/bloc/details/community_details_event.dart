import 'package:equatable/equatable.dart';

abstract class CommunityDetailsEvent extends Equatable {
  const CommunityDetailsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunityDetailsEvent extends CommunityDetailsEvent {
  final int communityId;
  const FetchCommunityDetailsEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}
