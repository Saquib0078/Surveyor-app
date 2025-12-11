import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;  // Use 'loc' as prefix for the 'location' package
import 'package:geocoding/geocoding.dart' as geo;

class GoogleMapScreen extends StatefulWidget {
  final Function(LatLng, bool) onLocationSelected; // Updated to include a bool

  GoogleMapScreen({required this.onLocationSelected});

  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController? mapController;
  final LatLng _initialPosition = LatLng(28.6139, 77.2090); // Set to New Delhi, India
  loc.Location location = loc.Location(); // Use the 'loc' prefix here
  bool _serviceEnabled = false;
  loc.PermissionStatus? _permissionGranted; // Use the 'loc' prefix here
  LatLng? _selectedLocation;
  Marker? _selectedMarker; // Marker for the selected location
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }
  }

  void _onMapTap(LatLng position) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(), // Loader
        );
      },
    );

    try {
      // Fetch the address after a short delay to simulate loading
      await Future.delayed(Duration(seconds: 1));

      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
      String address = placemarks.isNotEmpty
          ? '${placemarks.first.name}, ${placemarks.first.locality}, ${placemarks.first.country}'
          : 'Unknown Location';

      // Close the loading indicator
      Navigator.of(context).pop();

      // Update the selected location and marker
      setState(() {
        _selectedLocation = position;
        _selectedMarker = Marker(
          markerId: MarkerId('selected-location'),
          position: _selectedLocation!,
        );
      });

      // Show the confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Location"),
            content: Text("Do you want to select this location?\n\n$address"),
            actions: [
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the confirmation dialog
                },
              ),
              TextButton(
                child: Text("Confirm"),
                onPressed: () {
                  widget.onLocationSelected(position, true); // Send location and true as a bool
                  Navigator.of(context).pop(); // Close the confirmation dialog
                  Navigator.pop(context); // Close the map screen
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close the loading indicator if an error occurs
      Navigator.of(context).pop();
      print("Error occurred while fetching the location: $e");
    }
  }

  Future<void> _searchLocation() async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(_searchController.text);  // Use the 'geo' prefix here
      if (locations.isNotEmpty) {
        LatLng searchedLocation = LatLng(locations.first.latitude, locations.first.longitude);
        mapController?.animateCamera(CameraUpdate.newLatLng(searchedLocation));
        _onMapTap(searchedLocation);
      }
    } catch (e) {
      print("Error occurred while searching for the location: $e");
    }
  }

  void _onConfirm() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!, true); // Return true when confirmed
      Navigator.pop(context);  // Close the map screen
    } else {
      print('No location selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _onConfirm,  // Confirm selection
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12.0,
            ),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _selectedMarker != null ? {_selectedMarker!} : {}, // Display the marker
            onTap: _onMapTap,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu),
                            onPressed: () {
                              // Implement menu functionality
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search here',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              onSubmitted: (value) {
                                _searchLocation();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.mic),
                            onPressed: () {
                              // Implement voice search functionality
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "btn1",
                  child: Icon(Icons.layers),
                  mini: true,
                  onPressed: () {
                    // Implement layer selection functionality
                  },
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "btn2",
                  child: Icon(Icons.my_location),
                  onPressed: () async {
                    loc.LocationData currentLocation = await location.getLocation();
                    LatLng currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
                    mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
                    _onMapTap(currentLatLng);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
