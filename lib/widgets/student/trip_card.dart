import 'package:bus_just/services/student_service.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final bool isSelected;
  final Function(Trip) onSelected;

  const TripCard({
    super.key,
    required this.trip,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: StudentService.getTripDetails(trip.busId!, trip.driverId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Loading trip details...'),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading trip details'));
        }

        final bus = snapshot.data!['bus'] as Bus;
        final driver = snapshot.data!['driver'] as Driver;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _buildHeader(bus, driver),
                _buildTripInfo(bus),
                _buildStations(),
                _buildBookButton(isSelected),
              ],
            ),
          ),
        );
      },
    );
  }

 

  Widget _buildHeader(Bus bus, Driver driver) {
    return Row(
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
    );
  }

  Widget _buildTripInfo(Bus bus) {
    return Row(
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
    );
  }

  Widget _buildStations() {
    if (trip.stations == null || trip.stations!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStationRow(
                    trip.stations!.first.name ?? 'Starting Point',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildStationRow(
                    trip.stations!.last.name ?? 'Destination',
                    Colors.red,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trip.status == 'active'
                    ? Colors.green[100]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                trip.status?.toUpperCase() ?? 'N/A',
                style: TextStyle(
                  color:
                      trip.status == 'active' ? Colors.green[900] : Colors.grey[900],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationRow(String stationName, Color color) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            stationName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton(bool isSelected){
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:!isSelected ? () => onSelected(trip) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0072ff),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('Book Trip'),
      ),
    );
  }
}