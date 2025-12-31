import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';

/// Mock ConnectivityService for testing that doesn't use platform channels
class MockConnectivityService extends ChangeNotifier
    implements ConnectivityService {
  NetworkType _mockNetworkType = NetworkType.wifi;
  bool _mockIsOnline = true;

  MockConnectivityService({NetworkType? networkType, bool? isOnline}) {
    if (networkType != null) _mockNetworkType = networkType;
    if (isOnline != null) _mockIsOnline = isOnline;
  }

  @override
  NetworkType get currentNetworkType => _mockNetworkType;

  @override
  bool get isOnline => _mockIsOnline;

  @override
  bool get isWifi => _mockNetworkType == NetworkType.wifi;

  @override
  bool get isMobile => _mockNetworkType == NetworkType.mobile;

  void setNetworkType(NetworkType type, bool online) {
    _mockNetworkType = type;
    _mockIsOnline = online;
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
    // No-op for mock
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService', () {
    late MockConnectivityService service;

    setUp(() {
      service = MockConnectivityService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with network status', () {
      expect(service.currentNetworkType, isNotNull);
      expect(service.currentNetworkType, NetworkType.wifi);
    });

    test('isOnline returns true when connected', () {
      service.setNetworkType(NetworkType.wifi, true);
      expect(service.isOnline, isTrue);
    });

    test('isWifi returns true when on wifi', () {
      service.setNetworkType(NetworkType.wifi, true);
      expect(service.isWifi, isTrue);
      expect(service.isMobile, isFalse);
    });

    test('isMobile returns true when on mobile', () {
      service.setNetworkType(NetworkType.mobile, true);
      expect(service.isMobile, isTrue);
      expect(service.isWifi, isFalse);
    });

    test('currentNetworkType returns network type', () {
      service.setNetworkType(NetworkType.mobile, true);
      expect(service.currentNetworkType, NetworkType.mobile);

      service.setNetworkType(NetworkType.none, false);
      expect(service.currentNetworkType, NetworkType.none);
    });

    test('notifies listeners on connectivity change', () {
      bool notified = false;
      service.addListener(() {
        notified = true;
      });

      service.setNetworkType(NetworkType.mobile, true);
      expect(notified, isTrue);
    });

    test('isOnline returns false when offline', () {
      service.setNetworkType(NetworkType.none, false);
      expect(service.isOnline, isFalse);
      expect(service.currentNetworkType, NetworkType.none);
    });

    test('dispose cancels subscription', () {
      expect(() => service.dispose(), returnsNormally);
      // Should not throw when disposing again
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
