import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/community/data/models/community_settings_model.dart';

abstract class CommunitySettingsEvent extends Equatable {
  const CommunitySettingsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunitySettingsEvent extends CommunitySettingsEvent {
  final int communityId;
  const FetchCommunitySettingsEvent(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

class UpdateCommunitySettingsEvent extends CommunitySettingsEvent {
  final int communityId;
  final CommunitySettingsModel settings;

  const UpdateCommunitySettingsEvent(this.communityId, this.settings);

  @override
  List<Object?> get props => [communityId, settings];
}
