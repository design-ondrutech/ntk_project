import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends DashboardEvent {
  final int? locationId;
  const LoadDashboardStats(this.locationId);

  @override
  List<Object?> get props => [locationId];
}
