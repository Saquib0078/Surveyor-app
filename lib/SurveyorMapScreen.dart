import 'package:damagedetection1/surveyor/DriverDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AccidentIntimationScreen .dart';
import 'AvailableClaims.dart';
import 'UsePrefs.dart';
import 'helpers/APIConstants.dart';

class SurveyorMapScreen extends StatefulWidget {
  @override
  _SurveyorMapScreenState createState() => _SurveyorMapScreenState();
}

class _SurveyorMapScreenState extends State<SurveyorMapScreen> {
  String? surveyorId;
  GoogleMapController? mapController;
  final LatLng _initialPosition = LatLng(20.7157566, 76.9916911);
  loc.Location location = loc.Location();
  Set<Marker> markers = {};
  LatLng? currentLocation;
  late FirebaseFirestore firestore;
  bool isSyncing = false;
  bool isLoadingLocation = false;

  Map<String, String> taskAccidentMap = {};

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    loadSurveyorId();
  }

  Future<void> loadSurveyorId() async {
    surveyorId = await UserPreferences.getSurveyorId();
    print('========== SURVEYOR ID LOADED ==========');
    print('Surveyor ID: $surveyorId');
    print('========================================');
    setState(() {});
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    firestore = FirebaseFirestore.instance;
    checkLocationPermission();
    syncTasksOnAppOpen();
  }

  Future<void> syncTasksOnAppOpen() async {
    await syncTasks();
  }

  Future<void> checkLocationPermission() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            isLoadingLocation = false;
          });
          _showLocationServiceDialog();
          return;
        }
      }

      // Check location permission
      loc.PermissionStatus permissionGranted = await location.hasPermission();

      // Check for deniedForever BEFORE requesting permission
      if (permissionGranted == loc.PermissionStatus.deniedForever) {
        setState(() {
          isLoadingLocation = false;
        });
        _showPermissionDeniedForeverDialog();
        return;
      }

      // If permission is denied, request it
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();

        // After requesting, check if it was granted
        if (permissionGranted == loc.PermissionStatus.deniedForever) {
          setState(() {
            isLoadingLocation = false;
          });
          _showPermissionDeniedForeverDialog();
          return;
        }

        if (permissionGranted != loc.PermissionStatus.granted) {
          setState(() {
            isLoadingLocation = false;
          });
          _showPermissionDeniedDialog();
          return;
        }
      }

      // If we get here, permission is granted
      await getCurrentLocation();

    } catch (e) {
      print('Error checking location permission: $e');
      setState(() {
        isLoadingLocation = false;
      });
      _showErrorSnackBar('Failed to get location: $e');
    }
  }

// Add these new dialog methods:

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Location Service Disabled')),
            ],
          ),
          content: Text(
            'Location service is required for this app to work. Please enable it in your device settings.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await checkLocationPermission(); // Retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('TRY AGAIN'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.location_off, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Location Permission Required')),
            ],
          ),
          content: Text(
            'This app needs location permission to show nearby tasks and navigate. Please grant the permission.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await checkLocationPermission(); // Retry
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('GRANT PERMISSION'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('Permission Permanently Denied')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location permission has been permanently denied. To use this app, please:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '1. Go to App Settings\n2. Find Permissions\n3. Enable Location',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings
                await location.requestPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('OPEN SETTINGS'),
            ),
          ],
        );
      },
    );
  }


  Future<void> getCurrentLocation() async {
    try {
      setState(() => isLoadingLocation = true);

      // Get location directly - permissions are already checked by checkLocationPermission()
      final locationData = await location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        throw Exception("Location coordinates returned null");
      }

      currentLocation = LatLng(locationData.latitude!, locationData.longitude!);

      setState(() => isLoadingLocation = false);

      // Update map camera
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: currentLocation!, zoom: 15.0),
          ),
        );
      }

      print('========== LOCATION OBTAINED ==========');
      print('Latitude: ${locationData.latitude}');
      print('Longitude: ${locationData.longitude}');
      print('======================================');

    } on PlatformException catch (e) {
      print("PlatformException: $e");
      setState(() => isLoadingLocation = false);
      
      // If permission error, redirect to permission check
      if (e.code == 'PERMISSION_DENIED' || e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        await checkLocationPermission();
      } else {
        _showErrorSnackBarWithRetry("Platform error: ${e.message}", onRetry: getCurrentLocation);
      }

    } catch (e) {
      print('========== LOCATION ERROR ==========');
      print('Error: $e');
      print('===================================');

      setState(() => isLoadingLocation = false);

      _showErrorSnackBarWithRetry("Error getting location", onRetry: getCurrentLocation);
    }
  }



  void _showErrorSnackBarWithRetry(String message, {required Function onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            onRetry();
          },
        ),
      ),
    );
  }


  Future<void> syncTasks() async {
    if (currentLocation == null) {
      print('Current location not available');
      _showWarningSnackBar('Getting your location... Please wait.');

      await getCurrentLocation();

      if (currentLocation == null) {
        _showErrorSnackBar('Unable to get your location. Please check location permissions and try again.');
        return;
      }
    }

    setState(() {
      isSyncing = true;
    });

    final url = Uri.parse('${APIConstants.baseUrl}/fw_damage/sync_surveyor');

    final requestBody = {
      "lat": currentLocation!.latitude.toString(),
      "lng": currentLocation!.longitude.toString(),
      "status": "available",
      "suv_id": surveyorId
    };

    print('========== SYNC REQUEST ==========');
    print('URL: $url');
    print('Body: ${json.encode(requestBody)}');
    print('==================================');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      print('========== SYNC RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('===================================');

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          final surveyorData = data['surveyor_data'];
          if (surveyorData != null) {
            print('Surveyor ID: ${surveyorData['id'] ?? 'N/A'}');
            print('Last Updated: ${surveyorData['last_updated'] ?? 'N/A'}');
            print('Status: ${surveyorData['status'] ?? 'N/A'}');
            print('Task Count: ${surveyorData['task_count'] ?? 'N/A'}');
          }

          final taskData = data['task_data'];
          if (taskData != null && taskData.isNotEmpty) {
            for (var task in taskData) {
              String taskId = task['task_id'].toString();
              String accidentId = task['accident_id'].toString();
              taskAccidentMap[taskId] = accidentId;
            }

            // await saveSurveyorTasksToFirestore(data);
            updateMarkers(taskData);
            _showSuccessSnackBar(data['message'] ?? 'Tasks synced successfully! Found ${taskData.length} tasks.');
          } else {
            _showWarningSnackBar('No tasks available for surveyor');
          }
        } else {
          String errorMessage = data['message'] ?? 'Failed to sync tasks';
          _showErrorSnackBar(errorMessage);
        }
      } else if (response.statusCode == 400) {
        String errorMessage = data['message'] ?? 'Bad request';
        _showErrorSnackBar('Bad Request: $errorMessage');
      } else if (response.statusCode == 401) {
        String errorMessage = data['message'] ?? 'Unauthorized';
        _showErrorSnackBar('Unauthorized: $errorMessage');
      } else if (response.statusCode == 404) {
        String errorMessage = data['message'] ?? 'Resource not found';
        _showErrorSnackBar('Not Found: $errorMessage');
      } else if (response.statusCode == 500) {
        String errorMessage = data['message'] ?? 'Server error';
        _showErrorSnackBar('Server Error: $errorMessage');
      } else {
        String errorMessage = data['message'] ?? 'Failed to sync tasks (${response.statusCode})';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      print('========== SYNC ERROR ==========');
      print('Error: $e');
      print('================================');
      _showErrorSnackBar('Network error: $e');
    } finally {
      setState(() {
        isSyncing = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            if (message.toLowerCase().contains('location')) {
              getCurrentLocation();
            } else {
              syncTasks();
            }
          },
        ),
      ),
    );
  }

  Future<void> saveSurveyorTasksToFirestore(Map<String, dynamic> data) async {
    try {
      await firestore.collection('surveyor_tasks').doc(surveyorId).collection('responses').add({
        'timestamp': FieldValue.serverTimestamp(),
        'data': data,
      });
    } catch (e) {
      print('Error saving data to Firestore: $e');
      _showErrorSnackBar('Failed to save data locally: $e');
    }
  }

// ========== UPDATED: Parse location from flat structure (location_lat, location_long) ==========
  void updateMarkers(List<dynamic> tasks) {
    print('========== UPDATING MARKERS ==========');
    print('Total tasks received: ${tasks.length}');

    Set<Marker> newMarkers = {};
    int successCount = 0;
    int failedCount = 0;
    Map<String, String> failureReasons = {};

    for (var task in tasks) {
      String taskId = task['task_id']?.toString() ?? 'unknown_$failedCount';

      try {
        print('\n>>> Processing Task: $taskId');

        // ========== EXTRACT COORDINATES FROM FLAT STRUCTURE ==========
        var coordinates = _extractCoordinatesFromTask(task, taskId);

        if (coordinates == null) {
          print('❌ Task $taskId: Could not extract coordinates');
          failedCount++;
          failureReasons[taskId] = 'Missing or invalid coordinates';
          continue;
        }

        double latitude = coordinates['lat']!;
        double longitude = coordinates['lng']!;

        print('✓ Task $taskId: Valid coordinates (lat: $latitude, lng: $longitude)');

        // ========== CREATE MARKER ==========
        String status = task['status']?.toString().toLowerCase() ?? 'unknown';
        double markerColor = _getMarkerColor(status);

        newMarkers.add(Marker(
          markerId: MarkerId(taskId),
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: 'Task: $taskId',
            snippet: 'Status: $status',
          ),
          onTap: () => onMarkerTapped(task),
        ));

        successCount++;
        print('✓✓ Marker created successfully for Task $taskId');

      } catch (e, stackTrace) {
        print('❌❌ UNEXPECTED ERROR for Task $taskId: $e');
        print('Stack trace: $stackTrace');
        failedCount++;
        failureReasons[taskId] = 'Unexpected error: $e';
      }
    }

    // ========== SUMMARY ==========
    print('\n╔════════════════════════════════════════════════');
    print('║ MARKER UPDATE SUMMARY');
    print('╠════════════════════════════════════════════════');
    print('║ ✓ Success: $successCount markers');
    print('║ ✗ Failed: $failedCount tasks');

    if (failureReasons.isNotEmpty) {
      print('║');
      print('║ FAILURE DETAILS:');
      failureReasons.forEach((taskId, reason) {
        print('║ ├─ Task $taskId: $reason');
      });
    }

    print('╚════════════════════════════════════════════════\n');

    // Update UI
    setState(() {
      markers = newMarkers;
    });

    _showUserFeedback(successCount, failedCount, newMarkers);
  }

// ========== EXTRACT COORDINATES FROM TASK (handles both flat and nested structures) ==========
  Map<String, double>? _extractCoordinatesFromTask(Map<String, dynamic> task, String taskId) {
    print('  ├─ Extracting coordinates for Task $taskId...');

    dynamic latValue;
    dynamic lngValue;

    // ========== STRATEGY 1: Check for flat structure (location_lat, location_long) ==========
    List<String> flatLatKeys = ['location_lat', 'locationLat', 'lat', 'latitude'];
    List<String> flatLngKeys = ['location_long', 'location_lng', 'locationLong', 'locationLng', 'lng', 'long', 'longitude'];

    for (var key in flatLatKeys) {
      if (task.containsKey(key) && task[key] != null) {
        latValue = task[key];
        print('  ├─ Found flat lat field: $key = $latValue');
        break;
      }
    }

    for (var key in flatLngKeys) {
      if (task.containsKey(key) && task[key] != null) {
        lngValue = task[key];
        print('  ├─ Found flat lng field: $key = $lngValue');
        break;
      }
    }

    // ========== STRATEGY 2: Check for nested structure (location.lat, location.lng) ==========
    if (latValue == null || lngValue == null) {
      if (task.containsKey('location') && task['location'] != null && task['location'] != 'null' && task['location'] != '') {
        print('  ├─ Found location object, parsing nested structure...');

        var locationData = task['location'];

        // Parse if it's a JSON string
        if (locationData is String) {
          try {
            locationData = json.decode(locationData);
            print('  ├─ Parsed location JSON string');
          } catch (e) {
            print('  ├─ Failed to parse location JSON: $e');
            locationData = null;
          }
        }

        if (locationData is Map) {
          List<String> nestedLatKeys = ['lat', 'latitude', 'Lat', 'Latitude'];
          List<String> nestedLngKeys = ['lng', 'long', 'lon', 'longitude', 'Lng', 'Long'];

          for (var key in nestedLatKeys) {
            if (locationData.containsKey(key)) {
              latValue = locationData[key];
              print('  ├─ Found nested lat: $key = $latValue');
              break;
            }
          }

          for (var key in nestedLngKeys) {
            if (locationData.containsKey(key)) {
              lngValue = locationData[key];
              print('  ├─ Found nested lng: $key = $lngValue');
              break;
            }
          }
        }
      }
    }

    // ========== VALIDATE AND CONVERT ==========
    if (latValue == null || lngValue == null) {
      print('  └─ ✗ Missing latitude or longitude');
      print('     Available task keys: ${task.keys.toList()}');
      return null;
    }

    // Handle empty strings
    if (latValue is String && latValue.trim().isEmpty) latValue = null;
    if (lngValue is String && lngValue.trim().isEmpty) lngValue = null;

    if (latValue == null || lngValue == null) {
      print('  └─ ✗ Latitude or longitude is empty string');
      return null;
    }

    // Convert to double
    double? lat;
    double? lng;

    try {
      lat = double.parse(latValue.toString());
      lng = double.parse(lngValue.toString());
    } catch (e) {
      print('  └─ ✗ Failed to parse coordinates to double: $e');
      return null;
    }

    // Validate range
    if (lat < -90 || lat > 90) {
      print('  └─ ✗ Latitude out of range: $lat (must be -90 to 90)');
      return null;
    }

    if (lng < -180 || lng > 180) {
      print('  └─ ✗ Longitude out of range: $lng (must be -180 to 180)');
      return null;
    }

    print('  └─ ✓ Valid coordinates extracted (lat: $lat, lng: $lng)');
    return {'lat': lat, 'lng': lng};
  }

// ========== MARKER COLOR HELPER ==========
  double _getMarkerColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return BitmapDescriptor.hueGreen;
      case 'rejected':
        return BitmapDescriptor.hueRed;
      case 'submitted':
        return BitmapDescriptor.hueYellow;
      case 'completed':
        return BitmapDescriptor.hueOrange;
      case 'inprogress':
        return BitmapDescriptor.hueBlue;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

// ========== USER FEEDBACK HELPER ==========
  void _showUserFeedback(int successCount, int failedCount, Set<Marker> markers) {
    if (successCount > 0 && failedCount == 0) {
      _showSuccessSnackBar('✓ All $successCount tasks displayed on map');
      if (markers.isNotEmpty && mapController != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _fitMarkersInView(markers);
        });
      }
    } else if (successCount > 0 && failedCount > 0) {
      _showWarningSnackBar('$successCount tasks displayed, $failedCount have invalid location data');
      if (markers.isNotEmpty && mapController != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _fitMarkersInView(markers);
        });
      }
    } else if (failedCount > 0) {
      _showErrorSnackBar('Could not display any tasks. All $failedCount tasks have invalid location data. Check console logs.');
    } else {
      _showWarningSnackBar('No tasks received from server');
    }
  }
// Add this new method to auto-zoom to show all markers
  void _fitMarkersInView(Set<Marker> markers) {
    if (markers.isEmpty || mapController == null) return;

    try {
      double minLat = markers.first.position.latitude;
      double maxLat = markers.first.position.latitude;
      double minLng = markers.first.position.longitude;
      double maxLng = markers.first.position.longitude;

      for (var marker in markers) {
        if (marker.position.latitude < minLat) minLat = marker.position.latitude;
        if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
        if (marker.position.longitude < minLng) minLng = marker.position.longitude;
        if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
      }

      // Add padding
      double latPadding = (maxLat - minLat) * 0.1;
      double lngPadding = (maxLng - minLng) * 0.1;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      print('Error fitting markers in view: $e');
    }
  }
  void onMarkerTapped(Map<String, dynamic> task) {
    // ✅ ADD NULL CHECK
    if (task == null) {
      _showErrorSnackBar('Task data is not available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Task Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.tag, 'Task ID', task['task_id']?.toString() ?? 'N/A'),
                SizedBox(height: 12),
                _buildInfoRow(Icons.info_outline, 'Status', task['status']?.toString() ?? 'N/A'),
                SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, 'Estimated Time', task['estimated_time_to_complete']?.toString() ?? 'N/A'),
                SizedBox(height: 12),
                _buildInfoRow(Icons.local_shipping, 'Accident ID', task['accident_id']?.toString() ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            // ✅ ADD NULL CHECK FOR STATUS
            if (task['status']?.toString() == 'assigned') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        String? taskId = task['task_id']?.toString();
                        if (taskId != null) {
                          rejectTask(taskId);
                        } else {
                          _showErrorSnackBar('Task ID not available');
                        }
                      },
                      icon: Icon(Icons.close, size: 18),
                      label: Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        String? taskId = task['task_id']?.toString();
                        if (taskId != null) {
                          acceptTask(taskId);
                        } else {
                          _showErrorSnackBar('Task ID not available');
                        }
                      },
                      icon: Icon(Icons.check, size: 18),
                      label: Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (task['status']?.toString() == 'inprogress') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        launchGoogleMaps(task);
                      },
                      icon: Icon(Icons.directions, size: 18),
                      label: Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade700),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        String? taskId = task['task_id']?.toString();
                        String accidentId = taskId != null ? (taskAccidentMap[taskId] ?? '') : '';

                        if (taskId != null && accidentId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DriverDetailsScreen(
                                taskId: taskId,
                                accidentId: accidentId,
                              ),
                            ),
                          );
                        } else {
                          _showErrorSnackBar('Task or Accident ID not available');
                        }
                      },
                      icon: Icon(Icons.assignment, size: 18),
                      label: Text('Start Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> acceptTask(String taskId) async {
    if (currentLocation == null) {
      _showErrorSnackBar('Current location not available');
      return;
    }

    _showLoadingDialog('Accepting task...');

    final requestBody = {
      "lat": currentLocation!.latitude.toString(),
      "lng": currentLocation!.longitude.toString(),
      "status": "busy",
      "suv_id": surveyorId,
      "task_id": taskId
    };

    print('========== ACCEPT TASK REQUEST ==========');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        Uri.parse(APIConstants.acceptTask),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Navigator.of(context).pop();

      print('========== ACCEPT TASK RESPONSE ==========');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          _showSuccessSnackBar('Task accepted successfully');
          await syncTasks();
        } else {
          _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to accept task');
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to accept task');
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('Error accepting task: $e');
      _showErrorSnackBar('Network error: $e');
    }
  }

  Future<void> rejectTask(String taskId) async {
    if (currentLocation == null) {
      _showErrorSnackBar('Current location not available');
      return;
    }

    TextEditingController rejectController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
              SizedBox(width: 12),
              Text('Reject Task'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rejectController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    child: Text('Submit'),
                    onPressed: () async {
                      if (rejectController.text.isNotEmpty) {
                        Navigator.of(context).pop();
                        await submitRejection(taskId, rejectController.text);
                      } else {
                        _showErrorSnackBar('Rejection reason is required');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> submitRejection(String taskId, String rejectReason) async {
    _showLoadingDialog('Rejecting task...');

    final requestBody = {
      "lat": currentLocation!.latitude.toString(),
      "lng": currentLocation!.longitude.toString(),
      "status": "reject",
      "suv_id": surveyorId,
      "task_id": taskId,
      "reject_reason": rejectReason
    };

    print('========== REJECT TASK REQUEST ==========');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        Uri.parse(APIConstants.rejectTask),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Navigator.of(context).pop();

      print('========== REJECT TASK RESPONSE ==========');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          _showSuccessSnackBar('Task rejected successfully');
          await syncTasks();
        } else {
          _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to reject task');
        }
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to reject task');
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('Error rejecting task: $e');
      _showErrorSnackBar('Network error: $e');
    }
  }

  void launchGoogleMaps(Map<String, dynamic> task) async {
    try {
      // ✅ NULL CHECKS AND ENHANCED PARSING
      if (task['location'] == null || task['location'] == 'null' || task['location'] == '') {
        _showErrorSnackBar('Location data not available');
        return;
      }

      // Handle if location is a string (might be JSON string)
      var locationData = task['location'];
      if (locationData is String) {
        try {
          locationData = json.decode(locationData);
        } catch (e) {
          _showErrorSnackBar('Invalid location data format');
          return;
        }
      }

      // Try multiple possible field names for latitude
      var lat = locationData['lat'] ?? locationData['latitude'] ?? locationData['Lat'] ?? locationData['Latitude'];
      
      // Try multiple possible longitude field names
      var lng = locationData['long'] ?? locationData['lng'] ?? locationData['lon'] ?? 
                locationData['longitude'] ?? locationData['Long'] ?? locationData['Lng'] ?? 
                locationData['Lon'] ?? locationData['Longitude'];

      if (lat == null || lng == null) {
        print('Location data available fields: ${locationData is Map ? locationData.keys.toList() : 'Not a Map'}');
        _showErrorSnackBar('Location coordinates not available');
        return;
      }

      // Handle if lat/lng are empty strings
      if (lat is String && lat.isEmpty) lat = null;
      if (lng is String && lng.isEmpty) lng = null;
      
      if (lat == null || lng == null) {
        _showErrorSnackBar('Location coordinates are empty');
        return;
      }

      final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showErrorSnackBar('Could not launch Google Maps');
      }
    } catch (e) {
      print('Error launching maps: $e');
      _showErrorSnackBar('Error opening maps: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Surveyor Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (surveyorId != null)
              Text(
                'ID: $surveyorId',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
              ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isLoadingLocation)
            Center(
              child: Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(right: 16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
          if (isSyncing)
            Center(
              child: Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(right: 16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.sync),
              onPressed: syncTasks,
              tooltip: 'Sync Tasks',
            ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'location',
            child: Icon(Icons.my_location),
            backgroundColor: Colors.blue.shade700,
            onPressed: () {
              if (currentLocation != null) {
                mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: currentLocation!, zoom: 15.0),
                  ),
                );
              } else {
                getCurrentLocation();
              }
            },
            tooltip: 'My Location',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'refresh',
            child: Icon(Icons.refresh),
            backgroundColor: Colors.green,
            onPressed: syncTasks,
            tooltip: 'Refresh Tasks',
          ),
        ],
      ),
    );
  }
}
