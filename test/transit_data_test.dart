import 'package:flutter_test/flutter_test.dart';
import 'package:eco_move/services/transit_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TransitDataService loads all real bus routes and bus stops', () async {
    final service = TransitDataService();
    await service.loadDatasets(forceReload: true);

    expect(service.isLoaded, true);
    expect(service.busRoutePolylines.length, greaterThan(800));
    expect(service.busStops.length, greaterThan(3000));
    expect(service.cachedBusPolylines.length, greaterThan(800));
    expect(service.cachedBusStopCircles.length, greaterThan(3000));
  });
}
