import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/screen/map/route_selection_screen.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AssignTripBottomSheet extends StatefulWidget {
  const AssignTripBottomSheet({super.key,required this.driver});
  final Driver driver;

  @override
  State<AssignTripBottomSheet> createState() => _AssignTripBottomSheetState();
}

class _AssignTripBottomSheetState extends State<AssignTripBottomSheet> {
      Bus? selectedBus;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                'Assign Trip to ${widget.driver.fullName}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Available Bus:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.instance.getStreamedData("buses",
                    condition: 'isActive', value: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Text('No active buses available');
                  }

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final bus = Bus.fromMap(snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>);
                        return RadioListTile<Bus>(
                          title: Text('Bus ${bus.busNumber}'),
                          subtitle: Text('Capacity: ${bus.capacity}'),
                          value: bus,
                          groupValue: selectedBus,
                          onChanged: (Bus? value) {
                            setState(() {
                              selectedBus = value;
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: selectedBus == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        _showRouteSelectionMap(widget.driver, selectedBus!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072ff),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Select Route on Map'),
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
            _createTrip(driver, bus, stations );
          },
        ),
      ),
    );
  }
   Future<void> _createTrip(
      Driver driver, Bus bus,List<Station> stations) async {
    try {
      // Create a new trip document
      final tripRef = FirestoreService.instance.createEmptyDocumnet("trips");

      final trip = Trip(
        id: tripRef.id,
        driverId: driver.id,
        busId: bus.id??"",
        stations: stations,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Update the bus with the current trip and driver
      await FirestoreService.instance
          .updateDocument(collection: "buses", documentId: bus.id ?? "", data: {
        'currentTripId': tripRef.id,
        'isActive': false,
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