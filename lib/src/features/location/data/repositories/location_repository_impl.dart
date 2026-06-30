// ignore_for_file: use_null_aware_elements
import 'package:ntk_project/src/core/network/graphql_service.dart';
import 'package:ntk_project/src/features/location/domain/repositories/location_repository.dart';
import 'package:ntk_project/src/features/location/data/models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final GraphQLService _graphQLService;

  LocationRepositoryImpl(this._graphQLService);

  static const String _locationsQuery = r'''
    query Locations($type: LocationType, $parentId: Int) {
      locations(type: $type, parentId: $parentId) {
        id
        name
        type
        parentId
      }
    }
  ''';

  Future<List<LocationModel>> _fetchLocations({
    required String type,
    int? parentId,
  }) async {
    final result = await _graphQLService.performQuery(
      _locationsQuery,
      variables: {'type': type, if (parentId != null) 'parentId': parentId},
    );

    if (result.hasException) {
      final exception = result.exception!;
      if (exception.linkException != null) {
        throw Exception(
          'Network error: Please check if the server is running.',
        );
      }
      throw Exception(
        'GraphQL error: ${exception.graphqlErrors.isNotEmpty ? exception.graphqlErrors.first.message : exception.toString()}',
      );
    }

    final List data = result.data?['locations'] as List? ?? [];
    if (data.isEmpty) return [];

    return data
        .map<LocationModel>(
          (json) => LocationModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<List<LocationModel>> getDistricts() async {
    return getLocationList(type: 'DISTRICT');
  }

  @override
  Future<List<LocationModel>> getConstituencies({
    required int districtId,
  }) async {
    return _fetchLocations(type: 'TALUK', parentId: districtId);
  }

  @override
  Future<List<LocationModel>> getTowns({required int constituencyId}) async {
    return _fetchLocations(type: 'AREA', parentId: constituencyId);
  }

  @override
  Future<List<LocationModel>> getLocationList({
    int? parentId,
    required String type,
    int? selectedLocationId,
  }) async {
    const String query = r'''
      query GetLocationList($parentId: Int, $type: LocationType, $selectedLocationId: Int) {
        getLocationList(parentId: $parentId, type: $type, selectedLocationId: $selectedLocationId) {
          id
          name
          type
          parentId
        }
      }
    ''';

    final variables = <String, dynamic>{
      'type': type,
      if (parentId != null) 'parentId': parentId,
      if (selectedLocationId != null) 'selectedLocationId': selectedLocationId,
    };

    final result = await _graphQLService.performQuery(
      query,
      variables: variables,
    );

    if (result.hasException) {
      throw Exception(
        'Failed to fetch location list: ${result.exception.toString()}',
      );
    }

    final List data = result.data?['getLocationList'] as List? ?? [];
    return data
        .map<LocationModel>((json) => LocationModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<LocationModel>> getTargetableLocations({int? districtId}) async {
    const String query = r'''
      query GetTargetableLocations($districtId: Int) {
        getTargetableLocations(districtId: $districtId) {
          id
          name
          type
          parentId
        }
      }
    ''';

    final variables = <String, dynamic>{
      if (districtId != null) 'districtId': districtId,
    };

    final result = await _graphQLService.performQuery(
      query,
      variables: variables,
    );

    if (result.hasException) {
      throw Exception(
        'Failed to fetch targetable locations: ${result.exception.toString()}',
      );
    }

    final List data = result.data?['getTargetableLocations'] as List? ?? [];
    return data
        .map<LocationModel>((json) => LocationModel.fromJson(json))
        .toList();
  }
}
