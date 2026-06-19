import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_state.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/super_admin_dashboard.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/admin_dashboard.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/sub_admin_dashboard.dart';
import 'package:ntk_project/src/features/dashboard/presentation/screens/member_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    final loginData = authState.loginData;
    if (loginData != null) {
      final locationId = loginData.locationId;
      context.read<DashboardBloc>().add(
        LoadDashboardStats(locationId),
      );
      context.read<DashboardBloc>().add(
        LoadModerationStats(locationId),
      );
      context.read<PendingRequestsBloc>().add(
        LoadPendingRequests(locationId: locationId),
      );
      
      final role = loginData.role;
      if (role == 'ADMIN' && locationId != null) {
        // Load constituencies under the Admin's district
        context.read<LocationBloc>().add(DistrictSelected(locationId));
      } else {
        context.read<LocationBloc>().add(const FetchDistricts());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final role = authState.loginData?.role ?? 'MEMBER';
        if (role == 'SUPER_ADMIN') {
          return SuperAdminDashboard(authState: authState);
        } else if (role == 'ADMIN') {
          return AdminDashboard(authState: authState);
        } else if (role == 'SUB_ADMIN') {
          return SubAdminDashboard(authState: authState);
        } else {
          return MemberDashboard(authState: authState);
        }
      },
    );
  }
}
