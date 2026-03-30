import 'package:fpdart/fpdart.dart';

import '../entities/radar_bundle.dart';
import '../failures/radar_failure.dart';

abstract interface class RadarRepository {
  Future<Either<RadarFailure, RadarBundle>> fetchByDistrictRoute({
    required String fromDistrict,
    required String toDistrict,
    bool forceRefresh = false,
    String? requestId,
  });
}
