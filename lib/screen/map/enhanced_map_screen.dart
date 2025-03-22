import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bus_just/services/bus_tracking_service.dart';
import 'package:bus_just/models/bus_stop.dart';

class EnhancedMapScreen extends StatefulWidget {
  final LatLng? initialBusLocation;
  final String? tripId;

  const EnhancedMapScreen({
    super.key, 
    this.initialBusLocation,
    this.tripId,
  });

  @override
  _EnhancedMapScreenState createState() => _EnhancedMapScreenState();
}

class _EnhancedMapScreenState extends State<EnhancedMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  LatLng? _busLocation;
  List<BusStop>? _busStops;
  StreamSubscription<LatLng>? _busLocationSubscription;
  final BusTrackingService _busTrackingService = BusTrackingService.instance;
  
  // UI state
  bool _showBusInfo = false;
  String _estimatedArrival = 'Calculating...';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(24.7136, 46.6753), // Default to Riyadh, Saudi Arabia
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _busLocation = widget.initialBusLocation;
    _getCurrentLocation();
    if (widget.tripId != null) {
      _loadBusStops();
      _startBusTracking();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        
        // Add user location marker
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
        );
      });

      // If no bus location is provided, center on user's location
      if (_busLocation == null) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _loadBusStops() async {
    try {
      if (widget.tripId == null) return;
      
      final stops = await _busTrackingService.getBusStopsForTrip(widget.tripId!);
      setState(() {
        _busStops = stops;
        
        // Add bus stop markers
        for (int i = 0; i < stops.length; i++) {
          final stop = stops[i];
          final location = LatLng(
            stop.location.latitude,
            stop.location.longitude,
          );
          
          _markers.add(
            Marker(
              markerId: MarkerId('stop_${stop.id}'),
              position: location,
              infoWindow: InfoWindow(
                title: stop.name,
                snippet: 'Stop ${i + 1} of ${stops.length}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueYellow
              ),
            ),
          );
        }
        
        // Create route polyline if we have stops
        if (stops.length > 1) {
          final List<LatLng> polylinePoints = stops.map((stop) => 
            LatLng(stop.location.latitude, stop.location.longitude)
          ).toList();
          
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('bus_route'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        }
      });
      
      // Calculate ETA to next stop
      if (stops.isNotEmpty && _busLocation != null) {
        _updateEstimatedArrival();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bus stops: $e')),
        );
      }
    }
  }

  void _startBusTracking() {
    if (widget.tripId == null) return;
    
    // Start with initial location if provided
    if (widget.initialBusLocation != null) {
      setState(() {
        _busLocation = widget.initialBusLocation;
        _updateBusMarker();
        _centerMapOnBus();
      });
    }
    
    // Subscribe to real-time updates
    _busLocationSubscription = _busTrackingService
        .getBusLocationStream(widget.tripId!)
        .listen((location) {
          setState(() {
            _busLocation = location;
            _updateBusMarker();
            _updateEstimatedArrival();
          });
        });
  }

  void _updateBusMarker() {
    if (_busLocation == null) return;
    
    // Remove old bus marker if exists
    _markers.removeWhere((marker) => marker.markerId.value == 'bus');
    
    // Add updated bus marker
    _markers.add(
      Marker(
        markerId: const MarkerId('bus'),
        position: _busLocation!,
        infoWindow: const InfoWindow(title: 'Bus Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          setState(() {
            _showBusInfo = true;
          });
        },
      ),
    );
  }

  void _centerMapOnBus() {
    if (_busLocation == null || _mapController == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _busLocation!,
          zoom: 15.0,
        ),
      ),
    );
  }

  void _updateEstimatedArrival() {
    if (_busLocation == null || _busStops == null || _busStops!.isEmpty) return;
    
    // Find the next stop
    final nextStop = _busStops!.first;
    
    // Calculate distance (simplified)
    final double distanceInKm = _calculateDistance(
      _busLocation!.latitude,
      _busLocation!.longitude,
      nextStop.location.latitude,
      nextStop.location.longitude,
    );
    
    // Assume average speed of 30 km/h
    final double averageSpeed = 30.0; // km/h
    
    // Calculate time in minutes
    final int timeInMinutes = (distanceInKm / averageSpeed * 60).round();
    
    setState(() {
      if (timeInMinutes < 1) {
        _estimatedArrival = 'Arriving now';
      } else {
        _estimatedArrival = '$timeInMinutes minutes';
      }
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simplified distance calculation using Euclidean distance
    // In a real app, you would use the Haversine formula or a mapping service API
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracker'),
        backgroundColor: const Color(0xFF0072ff),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.tripId != null) {
                _loadBusStops();
                _centerMapOnBus();
              } else {
                _getCurrentLocation();
              }
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _currentPosition != null
                ? () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          zoom: 15.0,
                        ),
                      ),
                    );
                  }
                : null,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072ff)))
              : GoogleMap(
                  initialCameraPosition: _busLocation != null
                      ? CameraPosition(
                          target: _busLocation!,
                          zoom: 15.0,
                        )
                      : _currentPosition != null
                          ? CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 15.0,
                            )
                          : _initialPosition,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_busLocation != null) {
                      _centerMapOnBus();
                    }
                  },
                ),
          
          // Bus info panel
          if (_showBusInfo && _busLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_bus, color: Color(0xFF0072ff)),
                            const SizedBox(width: 8),
                            const Text(
                              'Bus Information',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _showBusInfo = false;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_busStops != null && _busStops!.isNotEmpty) ...[  
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Next Stop: ${_busStops!.first.name}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Estimated arrival: $_estimatedArrival',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _centerMapOnBus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0072ff),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Center on Bus'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Show bus info button
          if (!_showBusInfo && _busLocation != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showBusInfo = true;
                  });
                },
                backgroundColor: const Color(0xFF0072ff),
                child: const Icon(Icons.info_outline),
              ),
            ),
        ],
  ) );
  }
  @override
void dispose() {
  _mapController?.dispose();
  _busLocationSubscription?.cancel();
  super.dispose();
}
  }

