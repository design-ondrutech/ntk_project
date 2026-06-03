import 'package:get_it/get_it.dart';
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/core/services/fcm_service.dart';

// Auth feature
import 'package:ntk_project/src/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ntk_project/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:ntk_project/src/features/auth/presentation/bloc/auth_bloc.dart';

// Location feature
import 'package:ntk_project/src/features/location/data/repositories/location_repository_impl.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_bloc.dart';

// Dashboard feature
import 'package:ntk_project/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:ntk_project/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:ntk_project/src/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Member feature
import 'package:ntk_project/src/features/members/data/repositories/member_repository_impl.dart';
import 'package:ntk_project/src/features/members/domain/repositories/member_repository.dart';
import 'package:ntk_project/src/features/members/presentation/bloc/member_bloc.dart';

// Event feature
import 'package:ntk_project/src/features/events/data/repositories/event_repository_impl.dart';
import 'package:ntk_project/src/features/events/domain/repositories/event_repository.dart';
import 'package:ntk_project/src/features/events/presentation/bloc/event_bloc.dart';

// User feature
import 'package:ntk_project/src/features/users/data/repositories/user_repository_impl.dart';
import 'package:ntk_project/src/features/users/domain/repositories/user_repository.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_bloc.dart';
import 'package:ntk_project/src/features/users/presentation/bloc/user_management_bloc.dart';

// Requests feature
import 'package:ntk_project/src/features/requests_broadcasts/data/repositories/request_repository_impl.dart';
import 'package:ntk_project/src/features/requests_broadcasts/domain/repositories/request_repository.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/pending_requests_bloc.dart';
import 'package:ntk_project/src/features/requests_broadcasts/presentation/bloc/request_bloc.dart';

// Community feature
import 'package:ntk_project/src/features/community/data/repositories/community_repository_impl.dart';
import 'package:ntk_project/src/features/community/domain/repositories/community_repository.dart';
import 'package:ntk_project/src/features/community/presentation/bloc/community_bloc.dart';

// Notifications feature
import 'package:ntk_project/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:ntk_project/src/features/notifications/domain/repositories/notification_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Core / Network ──────────────────────────────────────
  sl.registerLazySingleton<GraphQLService>(() => GraphQLService());
  sl.registerLazySingleton<FCMService>(() => FCMService());

  // ─── Repositories ────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MemberRepository>(() => MemberRepositoryImpl(sl()));
  sl.registerLazySingleton<EventRepository>(() => EventRepositoryImpl(sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()));
  sl.registerLazySingleton<RequestRepository>(
    () => RequestRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  // ─── BLoCs ───────────────────────────────────────────────
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<LocationBloc>(() => LocationBloc(sl()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl()));
  sl.registerFactory<MemberBloc>(() => MemberBloc(sl()));
  sl.registerFactory<EventBloc>(() => EventBloc(sl()));
  sl.registerFactory<UserManagementBloc>(() => UserManagementBloc(sl(), sl()));
  sl.registerFactory<UserBloc>(() => UserBloc(sl(), sl()));
  sl.registerFactory<PendingRequestsBloc>(() => PendingRequestsBloc(sl()));
  sl.registerFactory<RequestBloc>(() => RequestBloc(sl()));
  sl.registerFactory<CommunityBloc>(() => CommunityBloc(sl()));
}
