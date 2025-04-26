import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/services/firestore_service.dart';

class ActiveTripsList extends StatelessWidget {
  const ActiveTripsList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.instance.getStreamedData(
        "trips",
        condition: "status",
        value: "active",
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0072ff)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error loading trips:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No active trips'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final trip = Trip.fromMap(
                snapshot.data!.docs[index].data() as Map<String, dynamic>);
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
                    .then((snapshot) =>
                        snapshot.docs.first.data() as Map<String, dynamic>),
              ]).then((results) => {
                    'bus': Bus.fromMap(results[0]),
                    'driver': Driver.fromMap(results[1]),
                  }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading trip details...'),
                    ),
                  );
                }
 final bus = snapshot.data!['bus'] as Bus;
                final driver = snapshot.data!['driver'] as Driver;
               

               

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.blue.shade50,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${bus.busName}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '| #${bus.busNumber}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        driver.fullName ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              height: 80,
                              child: Image.asset("assets/images/bus.png"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.airline_seat_recline_normal,
                              size: 16,
                              color: Color(0xFF0072ff),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Capacity: ${bus.capacity}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.route,
                              size: 16,
                              color: Color(0xFF0072ff),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${((trip.distance ?? 0) / 1000).toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF0072ff),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trip.estimatedTimeMinutes ?? '0'} min',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (trip.stations != null && trip.stations!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey[200]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              trip.stations!.first.name ??
                                                  'Starting Point',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (trip.stations!.length > 1) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              padding:
                                                  const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red[100],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Container(
                                                decoration:
                                                    const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                trip.stations!.last.name ??
                                                    'Destination',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}