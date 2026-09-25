import 'package:geolocator/geolocator.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class StaffPosition {
  const StaffPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.capturedAt,
    this.fromCache = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? capturedAt;
  final bool fromCache;

  bool get isStale {
    final at = capturedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) > const Duration(minutes: 2);
  }
}

class LocationRequestResult {
  const LocationRequestResult._({this.position, this.failure});

  const LocationRequestResult.ok(StaffPosition position)
      : this._(position: position);

  const LocationRequestResult.fail(LocationFailure failure)
      : this._(failure: failure);

  final StaffPosition? position;
  final LocationFailure? failure;

  bool get isOk => position != null;
}

/// Shared GPS helpers for delivery routing and customer map pins.
class LocationHelpers {
  const LocationHelpers._();

  static StaffPosition? _cached;
  static DateTime? _lastRequestAt;

  static double distanceMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }

  static double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return distanceMeters(
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        ) /
        1000;
  }

  /// Human label: meters when &lt; 1 km, else kilometers.
  static String formatDistance(double? meters) {
    if (meters == null || meters.isNaN || meters.isInfinite) {
      return 'Location unavailable';
    }
    if (meters < 1000) return '${meters.round()} m';
    final km = meters / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  /// Prefer a fresh reading; reuse a recent cache to avoid re-prompting.
  static Future<LocationRequestResult> requestPosition({
    bool forceRefresh = false,
    bool requestPermissionIfNeeded = true,
  }) async {
    final cached = _cached;
    if (!forceRefresh &&
        cached != null &&
        cached.capturedAt != null &&
        DateTime.now().difference(cached.capturedAt!) <
            const Duration(seconds: 45)) {
      return LocationRequestResult.ok(
        StaffPosition(
          latitude: cached.latitude,
          longitude: cached.longitude,
          accuracyMeters: cached.accuracyMeters,
          capturedAt: cached.capturedAt,
          fromCache: true,
        ),
      );
    }

    // Debounce rapid permission prompts across screens.
    final last = _lastRequestAt;
    if (!forceRefresh &&
        last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 2) &&
        cached != null) {
      return LocationRequestResult.ok(cached);
    }
    _lastRequestAt = DateTime.now();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationRequestResult.fail(
            LocationFailure.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied &&
          requestPermissionIfNeeded) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationRequestResult.fail(
            LocationFailure.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationRequestResult.fail(
          LocationFailure.permissionPermanentlyDenied,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final result = StaffPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
        capturedAt: DateTime.now(),
      );
      _cached = result;
      return LocationRequestResult.ok(result);
    } catch (_) {
      if (cached != null) {
        return LocationRequestResult.ok(
          StaffPosition(
            latitude: cached.latitude,
            longitude: cached.longitude,
            accuracyMeters: cached.accuracyMeters,
            capturedAt: cached.capturedAt,
            fromCache: true,
          ),
        );
      }
      return const LocationRequestResult.fail(LocationFailure.unavailable);
    }
  }

  /// Legacy helper used by existing screens — returns null when denied.
  static Future<StaffPosition?> currentPosition(
      {bool throwOnError = false}) async {
    final result = await requestPosition(forceRefresh: true);
    if (result.isOk) return result.position;
    if (throwOnError) {
      switch (result.failure) {
        case LocationFailure.serviceDisabled:
          throw Exception(
              'Location services are turned off. Enable GPS and try again.');
        case LocationFailure.permissionDenied:
        case LocationFailure.permissionPermanentlyDenied:
          throw Exception(
            'Location permission denied. Allow location to mark the exact delivery point.',
          );
        default:
          throw Exception('Unable to determine location.');
      }
    }
    return null;
  }

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
