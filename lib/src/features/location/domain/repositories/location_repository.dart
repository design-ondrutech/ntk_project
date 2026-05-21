import 'package:ntk_project/src/features/location/data/models/location_model.dart';

abstract class LocationRepository {
  Future<List<LocationModel>> getDistricts();
  Future<List<LocationModel>> getConstituencies({required int districtId});
  Future<List<LocationModel>> getTowns({required int constituencyId});
  Future<List<LocationModel>> getLocationList({int? parentId, required String type});
}
