import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class FetchDistricts extends LocationEvent {
  const FetchDistricts();
}

class DistrictSelected extends LocationEvent {
  final int districtId;
  const DistrictSelected(this.districtId);

  @override
  List<Object?> get props => [districtId];
}

class ConstituencySelected extends LocationEvent {
  final int constituencyId;
  const ConstituencySelected(this.constituencyId);

  @override
  List<Object?> get props => [constituencyId];
}

class TownSelected extends LocationEvent {
  final int townId;
  const TownSelected(this.townId);

  @override
  List<Object?> get props => [townId];
}

class ResetLocation extends LocationEvent {
  const ResetLocation();
}

class LoadLocationList extends LocationEvent {
  final int? parentId;
  final String type;

  const LoadLocationList({this.parentId, required this.type});

  @override
  List<Object?> get props => [parentId, type];
}
