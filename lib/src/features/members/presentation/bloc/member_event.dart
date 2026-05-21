import 'package:equatable/equatable.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object?> get props => [];
}

class LoadMembers extends MemberEvent {
  final int? locationId;
  final String? search;
  final String? bloodGroup;

  const LoadMembers({
    this.locationId, 
    this.search, 
    this.bloodGroup,
  });

  @override
  List<Object?> get props => [locationId, search, bloodGroup];
}
