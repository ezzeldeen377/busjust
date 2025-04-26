import 'dart:async';
import 'dart:ui' as ui;

import 'package:bus_just/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/services/bus_tracking_service.dart';
import 'package:geolocator/geolocator.dart';

class EnhancedMapScreen extends StatefulWidget {
  final LatLng? initialBusLocation;
  final String busId;
  final List<Station> stations;

  const EnhancedMapScreen({
    super.key,
    this.initialBusLocation,
    required this.busId,
    required this.stations,
  });

  @override
  _EnhancedMapScreenState createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final BusTrackingService _busTrackingService = BusTrackingService();

  // Remove static _initialPosition
  // static const CameraPosition _initialPosition = CameraPosition(
  //   target: LatLng(24.7136, 46.6753), // Default to Riyadh, Saudi Arabia
  //   zoom: 14.0,
  // );
  late StreamSubscription<LatLng> _locationSubscription;
  LatLng? _currentUserLocation;
  bool _isLoadingLocation = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _stationIcon;

  @override
  void initState() {
    super.initState();
    _loadBusIcon();
    _loadStationIcon();
    if (widget.initialBusLocation != null) {
      _updateBusMarker(widget.initialBusLocation!);
    }
    if (widget.busId != null) {
      _startBusLocationTracking();
    }
    _getCurrentLocation();
    _addStationMarkers();
  }

  Future<void> _loadStationIcon() async {
    try {
      final Uint8List markerIcon =
          await _getBytesFromAsset('assets/images/station_icon.png', 80);
      _stationIcon = BitmapDescriptor.fromBytes(markerIcon);
    } catch (e) {
      // Fallback to default icon if loading fails
      _stationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load station icon: $e')),
        );
      }
    }

    // Add station markers after icon is loaded
    _addStationMarkers();
  }

  void _addStationMarkers() {
    if (widget.stations.isEmpty) return;

    setState(() {
      for (var station in widget.stations) {
        // Create a marker for each station
        _markers.add(
          Marker(
            markerId: MarkerId(station.name ?? ""),
            position: LatLng(station.point!.latitude, station.point!.longitude),
            infoWindow: InfoWindow(
              title: station.name,
              snippet: station.name,
            ),
            icon: _stationIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
          ),
        );
      }
    });
  }

  Future<void> _loadBusIcon() async {
    try {
      final Uint8List markerIcon =
          await _getBytesFromAsset('assets/images/bus_icon.png', 100);
      _busIcon = BitmapDescriptor.fromBytes(markerIcon);
    } catch (e) {
      // Fallback to default icon if loading fails
      _busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bus icon: $e')),
        );
      }
    }

    // Update existing bus marker if it exists
    if (widget.initialBusLocation != null) {
      _updateBusMarker(widget.initialBusLocation!);
    }
  }

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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        setState(() {
          _isLoadingLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location permissions are permanently denied')),
        );
      }
      return;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition();
      _updateUserLocationMarker(position);

      // Listen to position updates
      _positionStreamSubscription = Geolocator.getPositionStream().listen(
        _updateUserLocationMarker,
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error getting location updates: $e')),
            );
          }
        },
      );

      setState(() {
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: $e')),
        );
      }
    }
  }

  void _updateUserLocationMarker(Position position) {
    final userLocation = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentUserLocation = userLocation;

      // We're no longer adding a marker for the user location
      // Just storing the location for centering purposes
    });
  }

  void _centerOnUserLocation() {
    if (_currentUserLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentUserLocation!, 15),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get your current location')),
      );
    }
  }

  void _startBusLocationTracking() {
    _locationSubscription =
        _busTrackingService.getBusLocationStream(widget.busId).listen(
      (LatLng location) {
        if (mounted) {
          _updateBusMarker(location);
          _animateToLocation(location);
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error tracking bus: $error')),
          );
        }
      },
    );
  }

  void _updateBusMarker(LatLng location) {
    setState(() {
      // Remove old bus marker if exists
      _markers.removeWhere((marker) => marker.markerId.value == 'bus');

      // Add updated bus marker with custom icon
      _markers.add(
        Marker(
          markerId: const MarkerId('bus'),
          position: location,
          infoWindow: const InfoWindow(title: 'Bus Location'),
          icon: _busIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _animateToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Location'),
        backgroundColor: const Color(0xFF0072ff),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (!_isLoadingLocation && _currentUserLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentUserLocation!,
                zoom: 15.0,
              ),
              markers: _markers,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          if (_isLoadingLocation || _currentUserLocation == null)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'centerOnUser',
                  onPressed: _centerOnUserLocation,
                  backgroundColor: const Color(0xFF0072ff),
                  child: _isLoadingLocation
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.my_location, color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (widget.busId != null)
                  FloatingActionButton(
                    heroTag: 'centerOnBus',
                    onPressed: () {
                      if (widget.initialBusLocation != null) {
                        _animateToLocation(widget.initialBusLocation!);
                      }
                    },
                    backgroundColor: const Color(0xFF0072ff),
                    child:
                        const Icon(Icons.directions_bus, color: Colors.white),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
