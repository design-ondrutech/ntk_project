import 'package:equatable/equatable.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class LocationState extends Equatable {
  final List<LocationModel> districts;
  final List<LocationModel> constituencies;
  final List<LocationModel> towns;
  final List<LocationModel> locations;

  final LocationModel? selectedDistrict;
  final LocationModel? selectedConstituency;
  final LocationModel? selectedTown;
  final LocationModel? selectedLocation;

  final bool isLoadingDistricts;
  final bool isLoadingConstituencies;
  final bool isLoadingTowns;
  final bool isLoadingLocations;

  final String? errorMessage;

  const LocationState({
    this.districts = const [],
    this.constituencies = const [],
    this.towns = const [],
    this.locations = const [],
    this.selectedDistrict,
    this.selectedConstituency,
    this.selectedTown,
    this.selectedLocation,
    this.isLoadingDistricts = false,
    this.isLoadingConstituencies = false,
    this.isLoadingTowns = false,
    this.isLoadingLocations = false,
    this.errorMessage,
  });

  bool isLocationSelected(String role) {
    if (role == 'Super Admin') return true;
    if (role == 'Admin') return selectedDistrict != null && selectedConstituency != null;
    if (role == 'Sub Admin') {
      return selectedDistrict != null &&
          selectedConstituency != null &&
          selectedTown != null;
    }
    return false;
  }

  LocationState copyWith({
    List<LocationModel>? districts,
    List<LocationModel>? constituencies,
    List<LocationModel>? towns,
    List<LocationModel>? locations,
    LocationModel? selectedDistrict,
    LocationModel? selectedConstituency,
    LocationModel? selectedTown,
    LocationModel? selectedLocation,
    bool? isLoadingDistricts,
    bool? isLoadingConstituencies,
    bool? isLoadingTowns,
    bool? isLoadingLocations,
    String? errorMessage,
    bool clearSelectedDistrict = false,
    bool clearSelectedConstituency = false,
    bool clearSelectedTown = false,
    bool clearSelectedLocation = false,
    bool clearError = false,
  }) {
    return LocationState(
      districts: districts ?? this.districts,
      constituencies: constituencies ?? this.constituencies,
      towns: towns ?? this.towns,
      locations: locations ?? this.locations,
      selectedDistrict: clearSelectedDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
      selectedConstituency: clearSelectedConstituency ? null : (selectedConstituency ?? this.selectedConstituency),
      selectedTown: clearSelectedTown ? null : (selectedTown ?? this.selectedTown),
      selectedLocation: clearSelectedLocation ? null : (selectedLocation ?? this.selectedLocation),
      isLoadingDistricts: isLoadingDistricts ?? this.isLoadingDistricts,
      isLoadingConstituencies: isLoadingConstituencies ?? this.isLoadingConstituencies,
      isLoadingTowns: isLoadingTowns ?? this.isLoadingTowns,
      isLoadingLocations: isLoadingLocations ?? this.isLoadingLocations,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        districts,
        constituencies,
        towns,
        locations,
        selectedDistrict,
        selectedConstituency,
        selectedTown,
        selectedLocation,
        isLoadingDistricts,
        isLoadingConstituencies,
        isLoadingTowns,
        isLoadingLocations,
        errorMessage,
      ];
}
