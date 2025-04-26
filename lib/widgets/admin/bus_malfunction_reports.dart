import 'package:flutter/material.dart';
import 'package:bus_just/models/bus_malfunction.dart';
import 'package:bus_just/services/bus_service.dart';
import 'package:intl/intl.dart';

class BusMalfunctionReports extends StatelessWidget {
  const BusMalfunctionReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bus Malfunction Reports',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0072ff),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<BusMalfunction>>(
          stream: BusService.instance.getMalfunctionReports(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = snapshot.data!;

            if (reports.isEmpty) {
              return const Center(
                child: Text('No malfunction reports'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final malfunction = reports[index];
                final formattedDate = DateFormat('MMM d, yyyy – hh:mm a').format(malfunction.timestamp);

                // Severity color mapping
                Color severityColor;
                switch ((malfunction.severity ?? '').toLowerCase()) {
                  case 'critical':
                    severityColor = Colors.red.shade700;
                    break;
                  case 'high':
                    severityColor = Colors.orange.shade700;
                    break;
                  case 'medium':
                    severityColor = Colors.amber.shade700;
                    break;
                  case 'low':
                    severityColor = Colors.green.shade700;
                    break;
                  default:
                    severityColor = Colors.grey.shade600;
                }

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.blue.shade100,
                      width: 1.2,
                    ),
                  ),
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(10.0), // Reduced from 18.0
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Bus & Issue
                        Row(
                          children: [
                            Icon(Icons.directions_bus, color: Colors.blue.shade800, size: 24), // Reduced size
                            const SizedBox(width: 6), // Reduced from 10
                            Expanded(
                              child: Text(
                                'Bus ${malfunction.busId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15, // Reduced from 17
                                  color: Color(0xFF0056b3),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Reduced
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: severityColor, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.priority_high, color: severityColor, size: 14), // Reduced
                                  const SizedBox(width: 3), // Reduced from 4
                                  Text(
                                    (malfunction.severity ?? 'Unknown').toUpperCase(),
                                    style: TextStyle(
                                      color: severityColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12, // Reduced from 13
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6), // Reduced from 10
                        // Issue Title
                        Text(
                          malfunction.issue,
                          style: const TextStyle(
                            fontSize: 14, // Reduced from 16
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22223B),
                          ),
                        ),
                        const SizedBox(height: 5), // Reduced from 8
                        // Description
                        Text(
                          malfunction.description,
                          style: const TextStyle(
                            fontSize: 13, // Reduced from 15
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                        const SizedBox(height: 8), // Reduced from 14
                        // Footer Row: Reporter, Date, Status, Action
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.indigo.shade400), // Reduced
                            const SizedBox(width: 3), // Reduced from 4
                            Text(
                              malfunction.reporterName,
                              style: TextStyle(
                                color: Colors.indigo.shade700,
                                fontSize: 12, // Reduced from 13
                              ),
                            ),
                            const SizedBox(width: 10), // Reduced from 14
                            Icon(Icons.access_time, size: 14, color: Colors.indigo.shade400), // Reduced
                            const SizedBox(width: 3), // Reduced from 4
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.indigo.shade700,
                                fontSize: 12, // Reduced from 13
                              ),
                            ),
                            const Spacer(),
                            Tooltip(
                              message: 'Mark as Fixed',
                              child: IconButton(
                                icon: Icon(
                                  malfunction.isFixed
                                      ? Icons.verified_rounded
                                      : Icons.build_circle_outlined,
                                  color: malfunction.isFixed ? Colors.green.shade700 : Colors.orange.shade700,
                                  size: 20, // Reduced
                                ),
                                onPressed: malfunction.isFixed
                                    ? null
                                    : () {
                                        BusService.instance.markMalfunctionAsFixed(malfunction.id);
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}