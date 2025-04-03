import 'package:bus_just/services/firestore_service.dart';
import 'package:bus_just/widgets/add_bus_bottom_sheet.dart';
import 'package:bus_just/widgets/assign_trip_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/driver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/screen/map/route_selection_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  void _showAddBusForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddBusBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072ff),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Trips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService.instance.getStreamedData("trips"),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No active trips'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final trip = Trip.fromMap(snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>);
                        return FutureBuilder<Map<String, dynamic>>(
                          future: Future.wait([
                            FirestoreService.instance
                                .getStreamedData('buses')
                                .first
                                .then((snapshot) => snapshot.docs
                                    .firstWhere((doc) => doc.id == trip.busId)
                                    .data() as Map<String, dynamic>),
                            FirestoreService.instance
                                .getStreamedData('users',
                                    condition: 'id', value: trip.driverId)
                                .first
                                .then((snapshot) => snapshot.docs.first.data()
                                    as Map<String, dynamic>),
                          ]).then((results) => {
                                'bus': Bus.fromMap(results[0]),
                                'driver': Driver.fromMap(results[1]),
                              }),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Card(
                                child: ListTile(
                                  leading: CircularProgressIndicator(),
                                  title: Text('Loading trip details...'),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text('No active trips'));
                            }

                            final bus = snapshot.data!['bus'] as Bus;
                            final driver = snapshot.data!['driver'] as Driver;

                            return Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ListTile(
                                leading: Icon(
                                  Icons.route_outlined,
                                  color: trip.status=="active"
                                      ? const Color(0xFF0072ff)
                                      : Colors.grey,
                                ),
                                title:
                                    Text('${bus.busName} (#${bus.busNumber})'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Driver: ${driver.fullName}'),
                                    Wrap(
                                      children: trip.stations!
                                        .map((station) => Container(
                                          margin: const EdgeInsets.all( 3),
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                          color: Colors.blue[100],

                                          ),
                                          child: Text(
                                                '${station.name}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                        ))
                                        .toList(),
                                    )
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trip.status=="active"
                                        ? Colors.blue[100]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    trip.status! ,
                                    style: TextStyle(
                                      color: trip.status=="active"
                                          ? Colors.green[900]
                                          : Colors.grey[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                             ) ),);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bus Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddBusForm,
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  label: const Text('Add New Bus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072ff),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService.instance.getStreamedData("buses"),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No buses available'));
                    }

                    return SizedBox(
                      height: 180, // Set a fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection:
                            Axis.horizontal, // Change to horizontal scrolling
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final bus = Bus.fromMap(snapshot.data!.docs[index]
                              .data() as Map<String, dynamic>);
                          return Container(
                            width: 200, // Fixed width for each card
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              color: Colors.white,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.grey.shade50,
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus,
                                      color: bus.isActive!
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      bus.busName ?? 'Unnamed Bus',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bus #: ${bus.busNumber}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Capacity: ${bus.capacity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bus.isActive!
                                            ? Colors.green[100]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        bus.isActive! ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          color: bus.isActive!
                                              ? Colors.green[900]
                                              : Colors.grey[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            )  );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registered Drivers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService.instance.getStreamedData("users",
                      condition: "role", value: "driver"),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Replace the ListView.builder with a horizontal layout
                    return SizedBox(
                      height: 240, // Set a fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection:
                            Axis.horizontal, // Change to horizontal scrolling
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final driver = Driver.fromMap(
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>);
                          return SizedBox(
                            width: 200,
                            child: Card(
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 50,
                                      child: Icon(Icons.person, size: 50),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      driver.fullName ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      driver.email,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showAssignTripSheet(driver);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0072ff),
                                        foregroundColor: Colors.white,
                                        minimumSize:
                                            const Size(double.infinity, 30),
                                      ),
                                      child: const Text('Assign Trip'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create trip functionality
        },
        backgroundColor: const Color(0xFF0072ff),
        tooltip: 'Create New Trip',
        child: const Icon(Icons.add_location),
      ),
    );
  }
  // Add these methods after the _buildAdminCard method

  void _showAssignTripSheet(Driver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssignTripBottomSheet(driver: driver),
    );
  }
}
