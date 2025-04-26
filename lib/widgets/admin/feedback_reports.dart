import 'package:bus_just/services/student_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/models/feedback.dart';
import 'package:bus_just/services/feedback_service.dart';
import 'package:intl/intl.dart';

class FeedbackReports extends StatelessWidget {
  const FeedbackReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Feedback Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StreamBuilder<List<FeedbackModel>>(
          stream: FeedbackService.instance.getFeedbackReports(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = snapshot.data!;

            if (reports.isEmpty) {
              return const Center(child: Text('No feedback reports available'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final feedback = reports[index];
                final formattedDate = DateFormat('MMM d, yyyy \'at\' hh:mm a')
                    .format(feedback.timestamp);

            return Card(
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.shade50, width: 2),
                  ),
                  color: Colors.white,
                  shadowColor: Colors.blue.withOpacity(0.08),
                  child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: StudentService.getStudentData(feedback.studentId),
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (studentSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'Error loading student data',
                              style: TextStyle(color: Colors.red.shade400),
                            ),
                          ),
                        );
                      }

                      final studentData = studentSnapshot.data?.data();
                      final studentName = studentData?['fullName'] ?? 'Unknown';

                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Student, Date, Route
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(Icons.person, color: Colors.blue.shade700),
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.route, size: 15, color: Colors.blueGrey.shade400),
                                          const SizedBox(width: 4),
                                          Text(
                                            feedback.routeName ?? 'N/A',
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Icon(Icons.access_time, size: 15, color: Colors.blueGrey.shade400),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Feedback Message
                            Text(
                              feedback.message,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Rating Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      ...List.generate(
                                        5,
                                        (index) => Icon(
                                          index < feedback.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 20,
                                          color: Colors.amber[700],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${feedback.rating}/5',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[800],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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