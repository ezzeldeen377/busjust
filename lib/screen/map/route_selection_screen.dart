import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class RouteSelectionScreen extends StatefulWidget {
  final Driver driver;
  final Bus bus;
  final Function(LatLng startPoint, LatLng endPoint) onRouteSelected;

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
  LatLng? _startPoint;
  LatLng? _endPoint;
  Set<Marker> _markers = {};
  
  // Use a default location in Saudi Arabia instead of (0,0) which could be invalid
  LatLng _center = const LatLng(24.7136, 46.6753); // Default to Riyadh, Saudi Arabia
  bool _isLoading = true;

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
            const SnackBar(content: Text('Location permissions are permanently denied')),
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
          SnackBar(content: Text('Failed to get current location: ${e.toString()}')),
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
      body: Stack(
        children: [
          // Only show the map when not loading
          if (!_isLoading)
            GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
                // Try to move camera to current location if available
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
          // Show loading indicator on top
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Point: ${_startPoint != null ? '${_startPoint!.latitude}, ${_startPoint!.longitude}' : 'Not selected'}'),
                      const SizedBox(height: 8),
                      Text('End Point: ${_endPoint != null ? '${_endPoint!.latitude}, ${_endPoint!.longitude}' : 'Not selected'}'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _startPoint != null && _endPoint != null
                      ? () {
                          widget.onRouteSelected(_startPoint!, _endPoint!);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072ff),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Save Route'),
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
                'Tap once to set start point, tap again to set end point',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng position) {
    setState(() {
      if (_startPoint == null) {
        // First tap - set start point
        _startPoint = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start Point'),
          ),
        );
      } else if (_endPoint == null) {
        // Second tap - set end point
        _endPoint = position;
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End Point'),
          ),
        );
      }
    });
  }
}