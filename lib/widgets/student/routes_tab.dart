import 'package:flutter/material.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/widgets/student/trip_card.dart';

class RoutesTab extends StatelessWidget {
  final List<Trip> availableTrips;
  final Trip? selectedTrip;
  final Function(Trip) onRouteSelected;

  const RoutesTab({
    super.key,
    required this.availableTrips,
    this.selectedTrip,
    required this.onRouteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Routes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: availableTrips.isEmpty
                ? const Center(child: Text('No routes available'))
                : ListView.builder(
                    itemCount: availableTrips.length,
                    itemBuilder: (context, index) => TripCard(
                      trip: availableTrips[index],
                      isSelected: selectedTrip!=null,
                      onSelected: onRouteSelected,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}