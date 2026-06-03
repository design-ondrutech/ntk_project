import 'package:equatable/equatable.dart';

abstract class CommunityListEvent extends Equatable {
  const CommunityListEvent();

  @override
  List<Object?> get props => [];
}

class FetchCommunitiesList extends CommunityListEvent {}

class CreateNewCommunity extends CommunityListEvent {
  final String name;
  final String? description;
  final String? image;
  final bool allowMemberMessages;

  const CreateNewCommunity({
    required this.name,
    this.description,
    this.image,
    this.allowMemberMessages = true,
  });

  @override
  List<Object?> get props => [name, description, image, allowMemberMessages];
}
