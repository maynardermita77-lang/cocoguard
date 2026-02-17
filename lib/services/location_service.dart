import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling location/GPS functionality
class LocationService {
  static String? _lastAddress;

  /// Check if location services are available
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Location permission permanently denied');
        // Open app settings so user can enable manually
        await openAppSettings();
        return false;
      }

      debugPrint('📍 Location permission granted');
      return true;
    } catch (e) {
      debugPrint('📍 Error requesting location permission: $e');
      return false;
    }
  }

  /// Get current location as a readable address
  /// Returns the address string or 'Unknown Location' if unavailable
  static Future<String> getLocationAddress() async {
    try {
      // First check/request permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('📍 No location permission');
        return 'Unknown Location';
      }

      // Get position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      debugPrint(
        '📍 Got coordinates: ${position.latitude}, ${position.longitude}',
      );

      // Store raw coordinates as fallback
      final coordsAddress =
          '${position.latitude.toStringAsFixed(4)}°N, ${position.longitude.toStringAsFixed(4)}°E';

      // Try to convert coordinates to address using reverse geocoding
      // This requires internet - will fail when offline
      try {
        // Check if running on web - geocoding may not work
        if (kIsWeb) {
          debugPrint('📍 Running on web, using coordinates as fallback');
          _lastAddress = coordsAddress;
          return coordsAddress;
        }

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        debugPrint('📍 Placemarks found: ${placemarks.length}');

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          // Debug: print all placemark fields
          debugPrint('📍 Placemark details:');
          debugPrint('   name: ${place.name}');
          debugPrint('   street: ${place.street}');
          debugPrint('   subLocality: ${place.subLocality}');
          debugPrint('   locality: ${place.locality}');
          debugPrint(
            '   subAdministrativeArea: ${place.subAdministrativeArea}',
          );
          debugPrint('   administrativeArea: ${place.administrativeArea}');
          debugPrint('   postalCode: ${place.postalCode}');
          debugPrint('   country: ${place.country}');

          // Build address string like: "Brgy. Dila, Santa Rosa City, Laguna, 4026"
          List<String> addressParts = [];

          // Street or name (more specific location)
          if (place.street != null &&
              place.street!.isNotEmpty &&
              place.street != place.name) {
            addressParts.add(place.street!);
          }

          // Sublocality (Barangay)
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }

          // Locality (City/Municipality)
          if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }

          // Sub-administrative area (can contain city info)
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty &&
              !addressParts.contains(place.subAdministrativeArea)) {
            addressParts.add(place.subAdministrativeArea!);
          }

          // Administrative area (Province)
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }

          // Postal code
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            addressParts.add(place.postalCode!);
          }

          if (addressParts.isNotEmpty) {
            final address = addressParts.join(', ');
            _lastAddress = address;
            debugPrint('📍 Final Address: $address');
            return address;
          }
        }
      } catch (e) {
        debugPrint('📍 Geocoding error (likely offline): $e');
        // Fall through to use coordinates
      }

      // Fallback: return formatted coordinates if geocoding fails (e.g., offline)
      _lastAddress = coordsAddress;
      debugPrint('📍 Using fallback coordinates: $coordsAddress');
      return coordsAddress;
    } catch (e) {
      debugPrint('📍 Error getting location: $e');
      return 'Unknown Location';
    }
  }

  /// Get last cached address
  static String? getLastAddress() {
    return _lastAddress;
  }

  /// Check if we have a valid cached address
  static bool hasLastAddress() {
    return _lastAddress != null && _lastAddress!.isNotEmpty;
  }
}
