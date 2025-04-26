import 'package:bus_just/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

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

  LatLng? _center; // Make nullable, remove default
  bool _isLoading = true;
  final TextEditingController _stationNameController = TextEditingController();
  BitmapDescriptor? _stationIcon;
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _loadStationIcon() async {
    try {
      final Uint8List markerIcon =
          await _getBytesFromAsset('assets/images/station_icon.png', 80);
      _stationIcon = BitmapDescriptor.fromBytes(markerIcon);
    } catch (e) {
      _stationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load station icon: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadStationIcon();
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
        if (_mapController != null && _center != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_center!, 14.0),
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
        title: Text('Select Route for ${widget.driver.fullName}',style: const TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF0072ff),
        iconTheme: const IconThemeData(color: Colors.white),
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
          if (!_isLoading && _center != null)
            GoogleMap(
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_center!, 14.0),
                );
              },
              initialCameraPosition: CameraPosition(
                target: _center!,
                zoom: 14.0,
              ),
              markers: _markers,
              onTap: _handleMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
          if (_isLoading || _center == null)
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _stationNameController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Station Name',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  hintText: 'Enter station name',
                  prefixIcon: Icon(Icons.location_on, color: const Color(0xFF0072ff), size: 22),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFF0072ff), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                autofocus: true,
              ),
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
                          icon: _stationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
