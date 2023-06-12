import 'package:sk_login_sofia/models/ride.dart';

abstract class IRidesService {
  Future<Ride> addAsync(Ride ride);
  Future<List<Ride>> searchAsync(RideSearchParameters parameters);
}

