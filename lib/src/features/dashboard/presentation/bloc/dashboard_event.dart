import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends DashboardEvent {
  final int? locationId;
  final int? filterLocationId;
  final int? userId;
  const LoadDashboardStats(this.locationId, {this.filterLocationId, this.userId});

  @override
  List<Object?> get props => [locationId, filterLocationId, userId];
}

class UpdateGlobalLocation extends DashboardEvent {
  final LocationModel? location;
  const UpdateGlobalLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class ResetDashboard extends DashboardEvent {
  const ResetDashboard();
}

class LoadModerationStats extends DashboardEvent {
  final int? locationId;
  const LoadModerationStats(this.locationId);

  @override
  List<Object?> get props => [locationId];
}
