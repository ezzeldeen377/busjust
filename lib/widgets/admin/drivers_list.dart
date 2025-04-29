import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:bus_just/widgets/assign_trip_bottom_sheet.dart';

class DriversList extends StatelessWidget {
  const DriversList({super.key});

  void _showAssignTripSheet(BuildContext context, Driver driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssignTripBottomSheet(driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registered Drivers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.instance.getStreamedDataWithTwoConditions(
            "users",
            condition1: "role",
            value1: "driver",
            condition2: "workStatus",
            value2: "online",
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No drivers registered'),
              );
            }

            return SizedBox(
              height: 310,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final driver = Driver.fromMap(
                    snapshot.data!.docs[index].data() as Map<String, dynamic>,
                  );
                  return SizedBox(
                    width: 220,
                    child: Card(
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
                              Colors.blue.shade50,
                              Colors.white,
                            ],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showAssignTripSheet(context, driver),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.blue.shade50,
                                    child: driver.profilePicture != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(48),
                                            child: Image.network(
                                              driver.profilePicture!,
                                              width: 96,
                                              height: 96,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            size: 48,
                                            color: Colors.blueGrey,
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  driver.fullName ?? 'Unknown Driver',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  driver.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<Bus?>(
                                  future: driver.assignedBus != null
                                      ? FirestoreService.instance
                                          .getBusData(driver.assignedBus!)
                                      : Future.value(null),
                                  builder: (context, busSnapshot) {
                                    String busDisplay = 'No bus assigned';
                                    if (busSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      busDisplay = 'Loading...';
                                    } else if (busSnapshot.hasData &&
                                        busSnapshot.data != null) {
                                      final bus = busSnapshot.data!;
                                      busDisplay =
                                          bus.busName ?? bus.busNumber ?? 'Unknown';
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.directions_bus,
                                            size: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              busDisplay,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}