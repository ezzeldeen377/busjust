import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/screen/map/route_selection_screen.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AssignTripBottomSheet extends StatefulWidget {
  const AssignTripBottomSheet({super.key, required this.driver});
  final Driver driver;

  @override
  State<AssignTripBottomSheet> createState() => _AssignTripBottomSheetState();
}

class _AssignTripBottomSheetState extends State<AssignTripBottomSheet> {
  Bus? selectedBus;
  
  // Define constants for consistent styling
  final Color _primaryColor = const Color(0xFF0072ff);
  final Color _secondaryColor = const Color(0xFF00c6ff);
  final double _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_borderRadius * 2),
          topRight: Radius.circular(_borderRadius * 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.directions_bus_filled_rounded,
                color: _primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Assign Trip to ${widget.driver.fullName}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.bus_alert_rounded,
                color: _primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Select Available Bus:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(color: Colors.grey.shade300),
            ),
            height: 220,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.instance.getStreamedData("buses",
                  condition: 'isActive', value: true),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_transfer_rounded,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No active buses available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final bus = Bus.fromMap(snapshot.data!.docs[index]
                        .data() as Map<String, dynamic>);
                    return RadioListTile<Bus>(
                      title: Text(
                        'Bus ${bus.busNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Capacity: ${bus.capacity} passengers',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      value: bus,
                      groupValue: selectedBus,
                      activeColor: _primaryColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      onChanged: (Bus? value) {
                        setState(() {
                          selectedBus = value;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: selectedBus == null
                ? null
                : () {
                    Navigator.pop(context);
                    _showRouteSelectionMap(widget.driver, selectedBus!);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
              ),
              elevation: 2,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_rounded),
                const SizedBox(width: 12),
                const Text(
                  'Select Route on Map',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
            ],
          ),
        );
  }
  void _showRouteSelectionMap(Driver driver, Bus bus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteSelectionScreen(
          driver: driver,
          bus: bus,
          onRouteSelected: (List<Station> stations) {
            _createTrip(driver, bus, stations);
          },
        ),
      ),
    );
  }
   Future<void> _createTrip(
      Driver driver, Bus bus,List<Station> stations) async {
    try {
      // Calculate distance between first and last station
      double totalDistance = 0;
      if (stations.length >= 2) {
        final firstStation = stations.first;
        final lastStation = stations.last;
        totalDistance =Geolocator.distanceBetween(firstStation.point!.latitude, firstStation.point!.longitude, lastStation.point!.latitude, lastStation.point!.longitude);
      }

      // Estimate time in minutes (assuming average speed of 40 km/h)
     // Convert distance to kilometers
  double totalDistanceKm = totalDistance / 1000;

  // Estimate time in minutes (assuming average speed of 40 km/h)
  int estimatedTimeMinutes = (totalDistanceKm * 60 / 40).round();
      // Create a new trip document
      final tripRef = FirestoreService.instance.createEmptyDocumnet("trips");

      final trip = Trip(
        id: tripRef.id,
        driverId: driver.id,
        busId: bus.id??"",
        stations: stations,
        status: 'pending',
        createdAt: DateTime.now(),
        distance: totalDistance,
        estimatedTimeMinutes: estimatedTimeMinutes,
      );

      // Update the bus with the current trip and driver
      await FirestoreService.instance
          .updateDocument(collection: "buses", documentId: bus.id ?? "", data: {
        'currentTripId': tripRef.id,
        'driverId': driver.id,
        'isActive': false,
      });
      await FirestoreService.instance
          .updateDocument(collection: "users", documentId: driver.id , data: {
        'assignedBus': bus.id,
      });


      // Create the trip
      await tripRef.set(trip.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip assigned successfully')),
        );
      }
    } catch (e) {
      print('Error assigning trip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning trip: $e')),
        );
      }
    }
  }
}
