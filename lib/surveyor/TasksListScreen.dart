import 'package:damagedetection1/surveyor/DriverDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

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
  String selectedFilter = 'assigned';
  TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  
  int start = 0;
  int length = 10;
  int totalRecords = 0;
  bool hasMore = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _loadSurveyorId();
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSurveyorId() async {
    surveyorId = await UserPreferences.getSurveyorId();
    print('========== SURVEYOR ID ==========');
    print('Surveyor ID: $surveyorId');
    print('=================================');
    if (surveyorId != null) {
      _fetchTasks();
    }
  }

  Future<void> _fetchTasks({bool loadMore = false}) async {
    if (surveyorId == null) {
      print('Cannot fetch tasks: Surveyor ID missing');
      return;
    }

    if (!loadMore) {
      setState(() {
        isLoading = true;
        start = 0;
        allTasks = [];
      });
    }

    final url = Uri.parse(APIConstants.surveyorTaskPagination);
    final requestBody = {
      "start": start,
      "length": length,
      "surveyor_id": surveyorId,
      "search": {
        "value": searchController.text.trim()
      },
      "status": selectedFilter == 'all' ? '' : selectedFilter
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
        setState(() {
          if (loadMore) {
            allTasks.addAll(data['data'] ?? []);
          } else {
            allTasks = data['data'] ?? [];
          }
          filteredTasks = allTasks;
          totalRecords = data['recordsFiltered'] ?? 0;
          hasMore = allTasks.length < totalRecords;
          isLoading = false;
        });

        print('========== TASKS LOADED ==========');
        print('Total tasks: ${allTasks.length}');
        print('Total records: $totalRecords');
        print('Has more: $hasMore');
        print('==================================');

        _animationController.forward(from: 0);
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar("Failed to fetch tasks (${response.statusCode})");
      }
    } catch (e) {
      print("========== FETCH TASKS ERROR ==========");
      print("Error: $e");
      print("=======================================");
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar("Network error: $e");
    }
  }

  void _loadMoreTasks() {
    if (!isLoading && hasMore) {
      setState(() {
        start += length;
      });
      _fetchTasks(loadMore: true);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
      start = 0;
    });
    _fetchTasks();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      setState(() {
        start = 0;
      });
      _fetchTasks();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Color(0xFF4CAF50);
      case 'inprogress':
        return Color(0xFF2196F3);
      case 'completed':
        return Color(0xFFFFC107);
      case 'discarded':
        return Color(0xFF9E9E9E);
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
      case 'completed':
        return Icons.check_circle_outline;
      case 'discarded':
        return Icons.delete_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  int _getTaskCountByStatus(String status) {
    if (status == 'all') return totalRecords;
    return allTasks.where((task) => task['task_status'] == status).length;
  }

  String _formatEstimatedTime(int? minutes) {
    if (minutes == null || minutes == 0) return 'N/A';
    
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }

  void _navigateToTaskLocation(Map<String, dynamic> task) async {
    final lat = task['task_lat'];
    final lng = task['task_lng'];
    
    if (lat == null || lng == null) {
      _showErrorSnackBar('Location coordinates not available');
      return;
    }

    // Try to parse coordinates
    double? latitude;
    double? longitude;
    
    try {
      latitude = double.parse(lat.toString());
      longitude = double.parse(lng.toString());
    } catch (e) {
      _showErrorSnackBar('Invalid location coordinates');
      return;
    }

    // Create Google Maps URL (works on both Android and iOS)
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    
    // Try to launch the URL
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open maps application');
    }
  }

  void _onTaskTapped(Map<String, dynamic> task) {
    print('========== TASK TAPPED (PROCESS) ==========');
    print('Full Task Data: ${json.encode(task)}');
    print('');
    print('Task Details:');
    print('  - Task ID: ${task['task_id'] ?? task['id'] ?? 'N/A'}');
    print('  - Task Status: ${task['task_status'] ?? 'N/A'}');
    print('  - Vehicle Number: ${task['vehicle_number'] ?? 'N/A'}');
    print('  - Policy Number: ${task['policy_number'] ?? 'N/A'}');
    print('  - Claim Number: ${task['claim_number'] ?? 'N/A'}');
    print('  - Address: ${task['address'] ?? 'N/A'}');
    print('  - Phone: ${task['phone'] ?? 'N/A'}');
    print('  - Estimated Time: ${task['estimated_time_to_complete'] ?? 'N/A'}');
    print('  - Latitude: ${task['lat'] ?? task['latitude'] ?? 'N/A'}');
    print('  - Longitude: ${task['lng'] ?? task['longitude'] ?? 'N/A'}');
    print('  - Created On: ${task['task_created_on'] ?? 'N/A'}');
    print('  - Assigned On: ${task['task_assigned_on'] ?? 'N/A'}');
    print('===========================================');
    
    final status = task['task_status']?.toString() ?? '';
    if (status == 'assigned') {
      _showAssignedDialog(task);
    } else if (status == 'inprogress') {
      _showInProgressDialog(task);
    } else if (status == 'completed') {
      _showCompletedDialog(task);
    } else if (status == 'rejected') {
      _showRejectedDialog(task);
    } else if (status == 'discarded') {
      _showDiscardedDialog(task);
    }
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
                  "New Task",
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
                _buildDialogInfoRow(Icons.directions_car, "Vehicle", task['vehicle_number'] ?? 'N/A'),
                SizedBox(height: 12),
                _buildDialogInfoRow(Icons.location_on, "Address", task['address'] ?? 'N/A'),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Text(
                      "Est. Time: ",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(
                        _formatEstimatedTime(task['estimated_time_to_complete']),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.phone, color: Colors.green.shade700),
                      onPressed: () {
                        if (task['phone'] != null) {
                          _makePhoneCall(task['phone']);
                        }
                      },
                      tooltip: 'Call Customer',
                    ),
                  ],
                ),
              ],
            ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              _buildDialogInfoRow(Icons.directions_car, "Vehicle", task['vehicle_number'] ?? 'N/A'),
              SizedBox(height: 12),
              _buildDialogInfoRow(Icons.location_on, "Address", task['address'] ?? 'N/A'),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    "Est. Time: ",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Text(
                      _formatEstimatedTime(task['estimated_time_to_complete']),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone, color: Colors.green.shade700),
                    onPressed: () {
                      if (task['phone'] != null) {
                        _makePhoneCall(task['phone']);
                      }
                    },
                    tooltip: 'Call Customer',
                  ),
                ],
              ),
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
                      _navigateToTaskLocation(task);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade700, width: 2),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      // Navigate to task details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverDetailsScreen(
                            taskId: task['vehicle_number']?.toString() ?? '',
                            accidentId: task['accident_id']?.toString() ?? '', // Use accident_id from task
                            taskData: task, // Pass task data for auto-fill
                          ),
                        ),
                      ).then((_) => _fetchTasks());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
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

  void _showCompletedDialog(Map<String, dynamic> task) {
    _showStyledDialog(
      title: "Task Completed",
      icon: Icons.check_circle,
      iconColor: Colors.amber.shade700,
      backgroundColor: Colors.amber.shade50,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogInfoRow(Icons.directions_car, "Vehicle", task['vehicle_number'] ?? 'N/A'),
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
                    style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogInfoRow(Icons.directions_car, "Vehicle", task['vehicle_number'] ?? 'N/A'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "This task has been rejected",
                    style: TextStyle(fontSize: 14, color: Colors.red.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      buttonColor: Colors.red.shade700,
    );
  }

  void _showDiscardedDialog(Map<String, dynamic> task) {
    _showStyledDialog(
      title: "Task Discarded",
      icon: Icons.delete_outline,
      iconColor: Colors.grey.shade700,
      backgroundColor: Colors.grey.shade50,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogInfoRow(Icons.directions_car, "Vehicle", task['vehicle_number'] ?? 'N/A'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade700, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "This task has been discarded",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade900, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      buttonColor: Colors.grey.shade700,
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

  void _showStyledDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
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
                child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptTask(Map<String, dynamic> task) async {
    // Get current location first
    Position? currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorSnackBar('Unable to get current location. Please enable location services.');
      return;
    }

    _showLoadingDialog("Accepting task...");

    final taskId = task['task_id']?.toString() ?? task['id']?.toString() ?? '';
    
    if (taskId.isEmpty) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Invalid task ID');
      return;
    }

    final requestBody = {
      "lat": currentLocation.latitude.toString(),
      "lng": currentLocation.longitude.toString(),
      "status": "busy",
      "suv_id": surveyorId,
      "task_id": taskId
    };

    print('========== ACCEPT TASK REQUEST ==========');
    print('URL: ${APIConstants.acceptTask}');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        Uri.parse(APIConstants.acceptTask),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      Navigator.of(context).pop(); // Close loading dialog

      print('========== ACCEPT TASK RESPONSE ==========');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showSuccessSnackBar('Task accepted successfully');
          _fetchTasks();
        } else {
          _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to accept task');
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to accept task');
        } catch (e) {
          _showErrorSnackBar('Failed to accept task: ${response.statusCode}');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error accepting task: $e');
      _showErrorSnackBar('Network error: $e');
    }
  }

  Future<void> _rejectTask(Map<String, dynamic> task, String rejectReason) async {
    // Get current location first
    Position? currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _showErrorSnackBar('Unable to get current location. Please enable location services.');
      return;
    }

    _showLoadingDialog("Rejecting task...");

    final taskId = task['task_id']?.toString() ?? task['id']?.toString() ?? '';
    
    if (taskId.isEmpty) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Invalid task ID');
      return;
    }

    final requestBody = {
      "lat": currentLocation.latitude.toString(),
      "lng": currentLocation.longitude.toString(),
      "status": "reject",
      "suv_id": surveyorId,
      "task_id": taskId,
      "reject_reason": rejectReason
    };

    print('========== REJECT TASK REQUEST ==========');
    print('URL: ${APIConstants.rejectTask}');
    print('Body: ${json.encode(requestBody)}');
    print('=========================================');

    try {
      final response = await http.post(
        Uri.parse(APIConstants.rejectTask),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      Navigator.of(context).pop(); // Close loading dialog

      print('========== REJECT TASK RESPONSE ==========');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==========================================');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          _showSuccessSnackBar('Task rejected successfully');
          _fetchTasks();
        } else {
          _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to reject task');
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          _showErrorSnackBar(responseData['message']?.toString() ?? 'Failed to reject task');
        } catch (e) {
          _showErrorSnackBar('Failed to reject task: ${response.statusCode}');
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print('Error rejecting task: $e');
      _showErrorSnackBar('Network error: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(message, style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
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
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'My Tasks',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by vehicle number, policy number...',
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {});
                _onSearchChanged();
              },
            ),
          ),

          // Filter Chips
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: 8),
                _buildFilterChip('Assigned', 'assigned'),
                SizedBox(width: 8),
                _buildFilterChip('In Progress', 'inprogress'),
                SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
                SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
                SizedBox(width: 8),
                _buildFilterChip('Discarded', 'discarded'),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: isLoading && allTasks.isEmpty
                ? Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                            SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!isLoading &&
                              hasMore &&
                              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            _loadMoreTasks();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredTasks.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredTasks.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildTaskCard(filteredTasks[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onFilterChanged(value);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['task_status']?.toString() ?? '';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return FadeTransition(
      opacity: _animationController,
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _onTaskTapped(task),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['vehicle_number'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            task['policy_number'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                Divider(height: 1),
                SizedBox(height: 16),

                // Details
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task['address'] ?? 'N/A',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Process Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow, size: 18),
                    label: Text('Process'),
                    onPressed: () => _onTaskTapped(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
