import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_event.dart';
import 'package:ntk_project/src/features/location/presentation/bloc/location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _locationRepository;

  LocationBloc(this._locationRepository) : super(const LocationState()) {
    on<FetchDistricts>(_onFetchDistricts);
    on<DistrictSelected>(_onDistrictSelected);
    on<ConstituencySelected>(_onConstituencySelected);
    on<TownSelected>(_onTownSelected);
    on<ResetLocation>(_onResetLocation);
    on<LoadLocationList>(_onLoadLocationList);
  }

  Future<void> _onLoadLocationList(
    LoadLocationList event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(isLoadingLocations: true, clearError: true));
    try {
      final locations = await _locationRepository.getLocationList(
        type: event.type,
        parentId: event.parentId,
      );
      emit(state.copyWith(
        locations: locations,
        isLoadingLocations: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingLocations: false,
        errorMessage: 'Failed to load locations: $e',
      ));
    }
  }

  void _onTownSelected(
    TownSelected event,
    Emitter<LocationState> emit,
  ) {
    if (state.towns.isEmpty) return;
    
    final selected = state.towns.firstWhere(
      (t) => t.id == event.townId,
      orElse: () => state.towns.first,
    );
    emit(state.copyWith(selectedTown: selected));
  }

  Future<void> _onFetchDistricts(
    FetchDistricts event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(isLoadingDistricts: true, clearError: true));
    try {
      final districts = await _locationRepository.getDistricts();
      emit(state.copyWith(
        districts: districts,
        isLoadingDistricts: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingDistricts: false,
        errorMessage: 'Failed to load districts: $e',
      ));
    }
  }

  Future<void> _onDistrictSelected(
    DistrictSelected event,
    Emitter<LocationState> emit,
  ) async {
    if (state.districts.isEmpty) return;

    // Find the selected district object
    final selected = state.districts.firstWhere(
      (d) => d.id == event.districtId,
      orElse: () => state.districts.first,
    );

    emit(state.copyWith(
      selectedDistrict: selected,
      constituencies: [],
      towns: [],
      clearSelectedConstituency: true,
      clearSelectedTown: true,
      isLoadingConstituencies: true,
      clearError: true,
    ));

    try {
      final constituencies = await _locationRepository.getConstituencies(
        districtId: event.districtId,
      );
      emit(state.copyWith(
        constituencies: constituencies,
        isLoadingConstituencies: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingConstituencies: false,
        errorMessage: 'Failed to load constituencies: $e',
      ));
    }
  }

  Future<void> _onConstituencySelected(
    ConstituencySelected event,
    Emitter<LocationState> emit,
  ) async {
    if (state.constituencies.isEmpty) return;

    final selected = state.constituencies.firstWhere(
      (c) => c.id == event.constituencyId,
      orElse: () => state.constituencies.first,
    );

    emit(state.copyWith(
      selectedConstituency: selected,
      towns: [],
      clearSelectedTown: true,
      isLoadingTowns: true,
      clearError: true,
    ));

    try {
      final towns = await _locationRepository.getTowns(
        constituencyId: event.constituencyId,
      );
      emit(state.copyWith(
        towns: towns,
        isLoadingTowns: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingTowns: false,
        errorMessage: 'Failed to load towns: $e',
      ));
    }
  }

  void _onResetLocation(
    ResetLocation event,
    Emitter<LocationState> emit,
  ) {
    emit(const LocationState());
  }
}
