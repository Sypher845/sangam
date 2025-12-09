import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.locationWhenInUse.status;
    
    return cameraStatus.isGranted && locationStatus.isGranted;
  }

  // Request all required permissions
  Future<bool> requestAllPermissions(BuildContext context) async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    
    // Request location permission
    final locationStatus = await Permission.locationWhenInUse.request();
    
    // Request background location permission (optional)
    await Permission.locationAlways.request();
    
    // Request storage permissions
    await Permission.storage.request();
    await Permission.photos.request();

    if (cameraStatus.isDenied || locationStatus.isDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return false;
    }

    if (cameraStatus.isPermanentlyDenied || locationStatus.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionPermanentlyDeniedDialog(context);
      }
      return false;
    }

    return cameraStatus.isGranted && locationStatus.isGranted;
  }

  // Check camera permission specifically
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Check location permission
  Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      // Use medium accuracy for faster location fix (good enough for hazard reporting)
      // This typically takes 1-3 seconds instead of 5-10 seconds
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Try to get last known location as fallback
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint('Error getting last known location: $e');
        return null;
      }
    }
  }

  // Show dialog when permissions are denied
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs camera and location permissions to capture hazard reports with location data. Please grant these permissions to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                requestAllPermissions(context);
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog when permissions are permanently denied
  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'Camera and location permissions have been permanently denied. Please enable them in Settings to use hazard capture functionality.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Initialize permissions on app start
  Future<void> initializePermissions(BuildContext context) async {
    final hasPermissions = await hasAllRequiredPermissions();
    if (!hasPermissions) {
      await requestAllPermissions(context);
    }
  }
}
