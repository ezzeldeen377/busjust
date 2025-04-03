import 'package:bus_just/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class RouteSelectionScreen extends StatefulWidget {
  final Driver driver;
  final Bus bus;
  final Function(List<Station>) onRouteSelected;

  const RouteSelectionScreen({
    Key? key,
    required this.driver,
    required this.bus,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  _RouteSelectionScreenState createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  GoogleMapController? _mapController;
  List<Station> _stationPoints = [];
  Set<Marker> _markers = {};
  bool _isSelectingStations = true;

  // Use a default location in Saudi Arabia instead of (0,0) which could be invalid
  LatLng _center =
      const LatLng(24.7136, 46.6753); // Default to Riyadh, Saudi Arabia
  bool _isLoading = true;
  final TextEditingController _stationNameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // Properly dispose of the map controller to prevent memory leaks
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permissions are permanently denied')),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        // Only animate camera if controller is initialized
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_center, 14.0),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to get current location: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Route for ${widget.driver.fullName}'),
        backgroundColor: const Color(0xFF0072ff),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _stationPoints.isNotEmpty
            ? () {
                setState(() {
                  _isSelectingStations = false;
                });
                widget.onRouteSelected(_stationPoints);
                Navigator.pop(context);
              }
            : null,
        label: const Text('End Selection'),
        icon: const Icon(Icons.check),
        backgroundColor: const Color(0xFF0072ff),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (!_isLoading)
            GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_center, 14.0),
                );
              },
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              markers: _markers,
              onTap: _handleMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Selected Stations'),
                      const SizedBox(height: 8),
                      if (_stationPoints.isNotEmpty) 
                        Text(_stationPoints.map((station) => " ${station.name ?? ''} ->").join()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: const Text(
                'Tap on the map to add station points. Press "End Selection" when done.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng station) {
    if (!_isSelectingStations) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Station Point ${_stationPoints.length + 1}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _stationNameController,
              decoration: const InputDecoration(
                labelText: 'Station Name',
                hintText: 'Enter station name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _stationNameController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_stationNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a station name')),
                      );
                      return;
                    }
                    setState(() {
                      _stationPoints.add(Station(
                          name: _stationNameController.text.trim(),
                          point: station.toGeoPoint()));
                      _markers.add(
                        Marker(
                          markerId:
                              MarkerId('station_${_stationPoints.length}'),
                          position: station,
                          icon: BitmapDescriptor.defaultMarker,
                          infoWindow: InfoWindow(
                              title: _stationNameController.text.trim()),
                        ),
                      );
                    });
                    _stationNameController.clear();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072ff),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Station'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
