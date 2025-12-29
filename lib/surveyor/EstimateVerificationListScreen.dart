import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'EstimateVerificationDetailScreen.dart';
import '../helpers/APIConstants.dart';

class EstimateVerificationListScreen extends StatefulWidget {
  final String taskType;
  final String pageTitle;

  const EstimateVerificationListScreen({
    Key? key,
    this.taskType = 'estimate_verification',
    this.pageTitle = 'Estimate Verification Tasks',
  }) : super(key: key);

  @override
  _EstimateVerificationListScreenState createState() => _EstimateVerificationListScreenState();
}

class _EstimateVerificationListScreenState extends State<EstimateVerificationListScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<dynamic> _claims = [];
  String? _errorMessage;
  int _start = 0;
  final int _length = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Debounce timer for search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchClaims();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMore) {
        _fetchMoreClaims();
      }
    }
  }

  Future<void> _fetchClaims() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _start = 0;
      _claims = [];
      _hasMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final surveyorId = prefs.getString('surveyor_id') ?? '';

      if (surveyorId.isEmpty) {
        setState(() {
          _errorMessage = 'Surveyor ID not found';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(APIConstants.getSurveyorClaims);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "surveyor_id": surveyorId,
          "task_type": widget.taskType,
          "start": _start,
          "search": {
            "value": _searchQuery
          },
          "length": _length
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newClaims = data['data'] ?? [];
        
        setState(() {
          _claims = newClaims;
          _isLoading = false;
          if (newClaims.length < _length) {
            _hasMore = false;
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load claims: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreClaims() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final surveyorId = prefs.getString('surveyor_id') ?? '';
      
      _start += _length;

      final url = Uri.parse(APIConstants.getSurveyorClaims);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "surveyor_id": surveyorId,
          "task_type": widget.taskType,
          "start": _start,
          "search": {
            "value": _searchQuery
          },
          "length": _length
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newClaims = data['data'] ?? [];
        
        setState(() {
          _claims.addAll(newClaims);
          _isLoadingMore = false;
          if (newClaims.length < _length) {
            _hasMore = false;
          }
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more claims')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more: $e')),
      );
    }
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query;
        });
        _fetchClaims();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by claim number, vehicle number...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          // Claims List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _claims.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                                SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty ? 'No tasks found' : 'No results for "$_searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: _claims.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _claims.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final claim = _claims[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(16),
                                  title: Text(
                                    claim['claim_number'] ?? 'Unknown Claim',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8),
                                      Text('Vehicle: ${claim['vehicle_number'] ?? 'N/A'}'),
                                      Text('Status: ${claim['task_status'] ?? 'N/A'}'),
                                      Text('Date: ${claim['task_created_on'] ?? 'N/A'}'),
                                    ],
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EstimateVerificationDetailScreen(
                                          claimId: claim['claim_ref_number'] ?? '',
                                          claimNumber: claim['claim_number'] ?? '',
                                          taskType: widget.taskType,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
