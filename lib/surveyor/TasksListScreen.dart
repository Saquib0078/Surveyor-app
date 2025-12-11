import 'package:damagedetection1/surveyor/DriverDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';

import '../AccidentIntimationScreen .dart';
import '../UsePrefs.dart';
import '../helpers/APIConstants.dart';

class TasksListScreen extends StatefulWidget {
  @override
  _TasksListScreenState createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> with SingleTickerProviderStateMixin {
  String? surveyorId;
  List<dynamic> allTasks = [];
  List<dynamic> filteredTasks = [];
  bool isLoading = false;
  String selectedFilter = 'all';
  loc.Location location = loc.Location();
  LatLng? _currentLocation;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    print('========== TasksListScreen INITIALIZED ==========');
    _loadSurveyorId();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSurveyorId() async {
    surveyorId = await UserPreferences.getSurveyorId();
    print('========== SURVEYOR ID ==========');
    print('Surveyor ID: $surveyorId');
    print('=================================');
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _showErrorSnackBar("Location service is disabled");
          return;
        }
      }

      // Check location permission
      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          _showErrorSnackBar("Location permission denied");
          return;
        }
      }

      loc.LocationData currentLocation = await location.getLocation();
      setState(() {
        _currentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });

      print('========== LOCATION OBTAINED ==========');
      print('Lat: ${currentLocation.latitude}');
      print('Lng: ${currentLocation.longitude}');
      print('=======================================');

      _fetchTasks();
    } catch (e) {
      print("========== LOCATION ERROR ==========");
      print("Error: $e");
      print("====================================");
      _showErrorSnackBar("Failed to get location: $e");
    }
  }

  Future<void> _fetchTasks() async {
    if (_currentLocation == null || surveyorId == null) {
      print('Cannot fetch tasks: Location or Surveyor ID missing');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('${APIConstants.baseUrl}/fw_damage/sync_surveyor');
    final requestBody = {
      "lat": _currentLocation!.latitude.toString(),
      "lng": _currentLocation!.longitude.toString(),
      "status": "available",
      "suv_id": surveyorId
    };

    print('========== FETCH TASKS REQUEST ==========');
    print('URL: $url');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('========== FETCH TASKS RESPONSE ==========');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            allTasks = data['task_data'] ?? [];
            _applyFilter();
          });

          print('========== TASKS LOADED ==========');
          print('Total tasks: ${allTasks.length}');
          if (allTasks.isNotEmpty) {
            print('First task structure: ${json.encode(allTasks[0])}');
          }
          print('==================================');

          _animationController.forward(from: 0);
        } else {
          print('API returned success: false');
          _showErrorSnackBar(data['message']?.toString() ?? "Failed to fetch tasks");
        }
      } else {
        print('API returned error status: ${response.statusCode}');
        _showErrorSnackBar("Failed to fetch tasks (${response.statusCode})");
      }
    } catch (e) {
      print("========== FETCH TASKS ERROR ==========");
      print("Error: $e");
      print("=======================================");
      _showErrorSnackBar("Network error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (selectedFilter == 'all') {
      filteredTasks = allTasks;
    } else {
      filteredTasks = allTasks.where((task) => task['status'] == selectedFilter).toList();
    }
    print('Applied filter: $selectedFilter, Filtered count: ${filteredTasks.length}');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Color(0xFF4CAF50);
      case 'inprogress':
        return Color(0xFF2196F3);
      case 'submitted':
        return Color(0xFFFF9800);
      case 'completed':
        return Color(0xFFFFC107);
      case 'rejected':
        return Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment_outlined;
      case 'inprogress':
        return Icons.pending_actions;
      case 'submitted':
        return Icons.upload_file;
      case 'completed':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  int _getTaskCountByStatus(String status) {
    if (status == 'all') return allTasks.length;
    return allTasks.where((task) => task['status'] == status).length;
  }

  void _onTaskTapped(Map<String, dynamic> task) {
    final status = task['status']?.toString() ?? '';
    if (status == 'submitted') {
      _showSubmittedDialog(task);
    } else if (status == 'assigned') {
      _showAssignedDialog(task);
    } else if (status == 'inprogress') {
      _showInProgressDialog(task);
    } else if (status == 'completed') {
      _showCompletedDialog(task);
    } else if (status == 'rejected') {
      _showRejectedDialog(task);
    }
  }

  void _showSubmittedDialog(Map<String, dynamic> task) {
    _showStyledDialog(
      title: "Claim Submitted",
      icon: Icons.check_circle_outline,
      iconColor: Colors.orange.shade700,
      backgroundColor: Colors.orange.shade50,
      borderColor: Colors.orange.shade200,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogInfoRow(Icons.tag, "Task ID", task['task_id']?.toString() ?? 'N/A'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, color: Colors.orange.shade700, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Claim is submitted and under progress",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      buttonColor: Colors.orange.shade700,
    );
  }

  void _showCompletedDialog(Map<String, dynamic> task) {
    _showStyledDialog(
      title: "Task Completed",
      icon: Icons.check_circle,
      iconColor: Colors.amber.shade700,
      backgroundColor: Colors.amber.shade50,
      borderColor: Colors.amber.shade200,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogInfoRow(Icons.tag, "Task ID", task['task_id']?.toString() ?? 'N/A'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Colors.amber.shade700, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "This task has been completed successfully",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      buttonColor: Colors.amber.shade700,
    );
  }

  void _showRejectedDialog(Map<String, dynamic> task) {
    _showStyledDialog(
      title: "Task Rejected",
      icon: Icons.cancel,
      iconColor: Colors.red.shade700,
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade200,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogInfoRow(Icons.tag, "Task ID", task['task_id']?.toString() ?? 'N/A'),
          if (task['reject_reason'] != null) ...[
            SizedBox(height: 12),
            _buildDialogInfoRow(Icons.info_outline, "Reason", task['reject_reason']?.toString() ?? 'N/A'),
          ],
        ],
      ),
      buttonColor: Colors.red.shade700,
    );
  }

  void _showAssignedDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.assignment_outlined, color: Colors.green.shade700, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "New Task Available",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow(Icons.tag, "Task ID", task['task_id']?.toString() ?? 'N/A'),
              SizedBox(height: 8),
              _buildDialogInfoRow(Icons.access_time, "Est. Time", task['estimated_time_to_complete']?.toString() ?? 'N/A'),
              if (task['accident_id'] != null) ...[
                SizedBox(height: 8),
                _buildDialogInfoRow(Icons.info_outline, "Accident ID", task['accident_id']?.toString() ?? 'N/A'),
              ],
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.close, size: 18),
                    label: Text("Reject"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showRejectDialog(task);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.check, size: 18),
                    label: Text("Accept"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _acceptTask(task);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  void _showInProgressDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pending_actions, color: Colors.blue.shade700, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Task in Progress",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow(Icons.tag, "Task ID", task['task_id']?.toString() ?? 'N/A'),
              SizedBox(height: 8),
              _buildDialogInfoRow(Icons.access_time, "Est. Time", task['estimated_time_to_complete']?.toString() ?? 'N/A'),
              if (task['accident_id'] != null) ...[
                SizedBox(height: 8),
                _buildDialogInfoRow(Icons.info_outline, "Accident ID", task['accident_id']?.toString() ?? 'N/A'),
              ],
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.navigation, size: 18),
                    label: Text("Navigate"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _launchGoogleMaps(task);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow, size: 18),
                    label: Text("Initiate"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverDetailsScreen(
                            taskId: task['task_id']?.toString() ?? '',
                            accidentId: task['accident_id']?.toString() ?? '',
                          ),
                        ),
                      ).then((_) => _fetchTasks());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  void _showRejectDialog(Map<String, dynamic> task) {
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
                  hintText: "Enter rejection reason",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    child: Text('Submit'),
                    onPressed: () {
                      if (rejectController.text.isNotEmpty) {
                        Navigator.of(context).pop();
                        _rejectTask(task, rejectController.text);
                      } else {
                        _showErrorSnackBar("Rejection reason is required");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  void _showStyledDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required Widget content,
    required Color buttonColor,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: content,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("OK"),
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          "$label: ",
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

  Future<void> _acceptTask(Map<String, dynamic> task) async {
    _showLoadingDialog("Accepting task...");

    final requestBody = {
      "lat": _currentLocation!.latitude.toString(),
      "lng": _currentLocation!.longitude.toString(),
      "status": "busy",
      "suv_id": surveyorId,
      "task_id": task['task_id']?.toString() ?? ''
    };

    print('========== ACCEPT TASK REQUEST ==========');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}/fw_damage/accept_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Navigator.of(context).pop(); // Close loading dialog

      print('========== ACCEPT TASK RESPONSE ==========');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          _showSuccessSnackBar('Task accepted successfully');
          _fetchTasks();
        } else {
          _showErrorSnackBar(responseData['message']?.toString() ?? "Failed to accept task");
        }
      } else {
        _showErrorSnackBar("Failed to accept task (${response.statusCode})");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print("========== ACCEPT TASK ERROR ==========");
      print("Error: $e");
      print("=======================================");
      _showErrorSnackBar("Network error: $e");
    }
  }

  Future<void> _rejectTask(Map<String, dynamic> task, String rejectReason) async {
    _showLoadingDialog("Rejecting task...");

    final requestBody = {
      "lat": _currentLocation!.latitude.toString(),
      "lng": _currentLocation!.longitude.toString(),
      "status": "reject",
      "suv_id": surveyorId,
      "task_id": task['task_id']?.toString() ?? '',
      "reject_reason": rejectReason
    };

    print('========== REJECT TASK REQUEST ==========');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        Uri.parse('${APIConstants.baseUrl}/fw_damage/reject_task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      Navigator.of(context).pop(); // Close loading dialog

      print('========== REJECT TASK RESPONSE ==========');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          _showSuccessSnackBar('Task rejected successfully');
          _fetchTasks();
        } else {
          _showErrorSnackBar(responseData['message']?.toString() ?? "Failed to reject task");
        }
      } else {
        _showErrorSnackBar("Failed to reject task (${response.statusCode})");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print("========== REJECT TASK ERROR ==========");
      print("Error: $e");
      print("=======================================");
      _showErrorSnackBar("Network error: $e");
    }
  }

  void _launchGoogleMaps(Map<String, dynamic> task) async {
    // Debug: Print the entire task to see structure
    print('========== TASK DATA FOR MAPS ==========');
    print(json.encode(task));
    print('========================================');

    // Try different possible location structures
    String? lat;
    String? lng;

    // Check if location is nested object
    if (task['location'] != null && task['location'] is Map) {
      lat = task['location']['lat']?.toString();
      lng = task['location']['long']?.toString() ?? task['location']['lng']?.toString();
    }
    // Check if location_lat and location_long are at root level
    else if (task['location_lat'] != null && task['location_long'] != null) {
      lat = task['location_lat']?.toString();
      lng = task['location_long']?.toString();
    }
    // Check if lat and lng are at root level
    else if (task['lat'] != null && task['lng'] != null) {
      lat = task['lat']?.toString();
      lng = task['lng']?.toString();
    }

    print('Extracted - Lat: $lat, Lng: $lng');

    if (lat == null || lng == null || lat == 'null' || lng == 'null' || lat == '0' || lng == '0') {
      _showErrorSnackBar("Location data not available for this task");
      return;
    }

    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';

    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        _showErrorSnackBar("Could not launch maps");
      }
    } catch (e) {
      print("Error launching maps: $e");
      _showErrorSnackBar("Error opening maps: $e");
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
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final crossAxisCount = isTablet ? 2 : 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${filteredTasks.length} task${filteredTasks.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Stats Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _getTaskCountByStatus('all'), Icons.list_alt),
                _buildStatItem('Assigned', _getTaskCountByStatus('assigned'), Icons.assignment),
                _buildStatItem('Progress', _getTaskCountByStatus('inprogress'), Icons.pending_actions),
                _buildStatItem('Done', _getTaskCountByStatus('completed'), Icons.check_circle),
              ],
            ),
          ),

          // Enhanced Filter Chips
          Container(
            height: 50,
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', 'all', Icons.apps),
                SizedBox(width: 10),
                _buildFilterChip('Assigned', 'assigned', Icons.assignment_outlined),
                SizedBox(width: 10),
                _buildFilterChip('In Progress', 'inprogress', Icons.pending_actions),
                SizedBox(width: 10),
                _buildFilterChip('Completed', 'completed', Icons.check_circle_outline),
                SizedBox(width: 10),
                _buildFilterChip('Submitted', 'submitted', Icons.upload_file),
                SizedBox(width: 10),
                _buildFilterChip('Rejected', 'rejected', Icons.cancel_outlined),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Tasks List
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading tasks...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : filteredTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                  SizedBox(height: 16),
                  Text(
                    'No tasks available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchTasks,
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchTasks,
              color: Colors.blue.shade700,
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isTablet ? 1.5 : 1.2,
                ),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return FadeTransition(
                    opacity: _animationController,
                    child: _buildEnhancedTaskCard(task),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = selectedFilter == value;
    final count = _getTaskCountByStatus(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
          _applyFilter();
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedTaskCard(Map<String, dynamic> task) {
    final status = task['status']?.toString() ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      elevation: 3,
      shadowColor: statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _onTaskTapped(task),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, statusColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Task ID
              Row(
                children: [
                  Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task['task_id']?.toString() ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Estimated Time
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      task['estimated_time_to_complete']?.toString() ?? 'N/A',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),

              if (task['accident_id'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ID: ${task['accident_id']?.toString() ?? 'N/A'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              Spacer(),

              // Action Button - FIXED
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _onTaskTapped(task),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white, // ✅ ADD THIS LINE
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero, // Ensure proper padding
                  ),
                  child: Text(
                    _getActionButtonText(status),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // ✅ Keep this as backup
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case 'assigned':
        return 'Accept Task';
      case 'inprogress':
        return 'Continue';
      case 'submitted':
        return 'View Status';
      case 'completed':
        return 'View Details';
      case 'rejected':
        return 'View Details';
      default:
        return 'Open';
    }
  }
}
