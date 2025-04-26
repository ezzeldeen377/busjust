import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/models/trip.dart';

class BusArrivalCard extends StatelessWidget {
  final DateTime? estimatedArrivalTime;
  final Trip? selectedTrip;
  final LatLng? busLocation;
  final VoidCallback onTrackPressed;
  final VoidCallback onEndTripPressed;

  const BusArrivalCard({
    super.key,
    this.estimatedArrivalTime,
    this.selectedTrip,
    this.busLocation,
    required this.onTrackPressed,
    required this.onEndTripPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
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
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Image.asset(
                "assets/images/bus.png",
                width: 60,
                height: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Bus Arrival',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: -0.5,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildArrivalTime(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalTime() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: estimatedArrivalTime != null
                ? const Color(0xFF00C853).withOpacity(0.15)
                : Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: estimatedArrivalTime != null
                    ? const Color(0xFF00C853)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                estimatedArrivalTime != null
                    ? '${estimatedArrivalTime!.difference(DateTime.now()).inMinutes < 0 ? 0 : estimatedArrivalTime!.difference(DateTime.now()).inMinutes} mins'
                    : 'No active trips',
                style: TextStyle(
                  color: estimatedArrivalTime != null
                      ? const Color(0xFF00C853)
                      : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: busLocation != null ? onTrackPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0072ff),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.route_outlined, size: 16, color: Colors.white),
            label: const Text('Track',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: selectedTrip != null ? onEndTripPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.white),
            label: const Text('End Trip',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}