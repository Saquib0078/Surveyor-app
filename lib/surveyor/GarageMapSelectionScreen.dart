import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../helpers/APIConstants.dart';

class GarageMapSelectionScreen extends StatefulWidget {
  final String? selectedGarageId;
  final String? accidentLocation; // For auto-search

  const GarageMapSelectionScreen({
    Key? key,
    this.selectedGarageId,
    this.accidentLocation,
  }) : super(key: key);

  @override
  State<GarageMapSelectionScreen> createState() => _GarageMapSelectionScreenState();
}

class _GarageMapSelectionScreenState extends State<GarageMapSelectionScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _selectedGarage;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _garages = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _currentSearch = '';

  @override
  void initState() {
    super.initState();
    // Auto-search with accident location if provided
    if (widget.accidentLocation != null && widget.accidentLocation!.isNotEmpty) {
      _searchController.text = widget.accidentLocation!;
      _currentSearch = widget.accidentLocation!;
    }
    _fetchGarages();
  }

  Future<void> _fetchGarages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(APIConstants.garageSearch),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': _currentSearch, // Search query
          'page': 1,
          'limit': 100,
        }),
      );

      print('========== GARAGE SEARCH API ==========');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('=======================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _garages = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
          _createMarkers();
        } else {
          throw Exception('API returned error status');
        }
      } else {
        throw Exception('Failed to load garages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching garages: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load garages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createMarkers() {
    if (_garages.isEmpty) return;

    _markers = _garages.where((garage) {
      // Only show garages that have valid coordinates
      final lat = garage['garage_latitude'];
      final lng = garage['garage_longitude'];
      
      // Check if coordinates exist and are not empty strings
      return lat != null && 
             lng != null &&
             lat.toString().isNotEmpty &&
             lng.toString().isNotEmpty &&
             lat.toString() != '' &&
             lng.toString() != '';
    }).map((garage) {
      final isSelected = garage['id']?.toString() == widget.selectedGarageId;
      
      return Marker(
        markerId: MarkerId(garage['id']?.toString() ?? ''),
        position: LatLng(
          double.parse(garage['garage_latitude'].toString()),
          double.parse(garage['garage_longitude'].toString()),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: garage['garage_name'] ?? 'Unknown Garage',
          snippet: garage['distance_km'] != null 
              ? '${garage['distance_km']} km away' 
              : garage['garage_city'] ?? '',
        ),
        onTap: () {
          _onMarkerTapped(garage);
        },
      );
    }).toSet();

    // Set selected garage if provided
    if (widget.selectedGarageId != null && _garages.isNotEmpty) {
      try {
        _selectedGarage = _garages.firstWhere(
          (g) => g['id']?.toString() == widget.selectedGarageId,
          orElse: () => _garages[0],
        );
      } catch (e) {
        print('Error finding selected garage: $e');
      }
    }

    setState(() {});
  }

  void _onMarkerTapped(Map<String, dynamic> garage) {
    setState(() {
      _selectedGarage = garage;
      // Update marker colors
      _markers = _garages.where((g) {
        final lat = g['garage_latitude'];
        final lng = g['garage_longitude'];
        return lat != null && 
               lng != null &&
               lat.toString().isNotEmpty &&
               lng.toString().isNotEmpty;
      }).map((g) {
        final isSelected = g['id']?.toString() == garage['id']?.toString();
        return Marker(
          markerId: MarkerId(g['id']?.toString() ?? ''),
          position: LatLng(
            double.parse(g['garage_latitude'].toString()),
            double.parse(g['garage_longitude'].toString()),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: g['garage_name'] ?? 'Unknown Garage',
            snippet: g['distance_km'] != null 
                ? '${g['distance_km']} km away' 
                : g['garage_city'] ?? '',
          ),
          onTap: () {
            _onMarkerTapped(g);
          },
        );
      }).toSet();
    });

    // Animate camera to selected garage
    final lat = garage['garage_latitude'];
    final lng = garage['garage_longitude'];
    if (lat != null && lng != null && lat.toString().isNotEmpty && lng.toString().isNotEmpty) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            double.parse(lat.toString()),
            double.parse(lng.toString()),
          ),
          14.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Garage on Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (!_isLoading && _garages.isNotEmpty)
              Text(
                '${_garages.length} garages found',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_selectedGarage != null)
            IconButton(
              onPressed: () {
                Navigator.pop(context, _selectedGarage);
              },
              icon: Icon(Icons.check, color: Colors.white),
              tooltip: 'Confirm Selection',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(19.0760, 72.8777), // Mumbai center
              zoom: 12.0,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade600),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by location...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            _currentSearch = value;
                          });
                          _fetchGarages();
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _currentSearch = '';
                          });
                          _fetchGarages();
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.blue.shade700),
                      onPressed: () {
                        setState(() {
                          _currentSearch = _searchController.text;
                        });
                        _fetchGarages();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Selected Garage Info Card
          if (_selectedGarage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.garage,
                              color: Colors.green.shade700,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedGarage!['garage_name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${_selectedGarage!['garage_city']}, ${_selectedGarage!['garage_state']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Divider(height: 1),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.blue.shade700),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _selectedGarage!['garage_phn_no'],
                                    style: TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.directions_car, size: 14, color: Colors.orange.shade700),
                                SizedBox(width: 4),
                                Text(
                                  '${_selectedGarage!['distance_km']} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context, _selectedGarage);
                          },
                          icon: Icon(Icons.check_circle, size: 20),
                          label: Text(
                            'Select This Garage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Legend
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Available',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Selected',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: EdgeInsets.all(40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          'Loading Garages...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
