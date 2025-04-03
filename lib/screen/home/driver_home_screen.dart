import 'package:bus_just/services/auth_service.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/trip.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Driver? _driver;
  Bus? _assignedBus;
  Trip? _currentTrip;
  List<Trip> _pendingTrips = [];
  bool _isOnline = false;
  StreamSubscription<Position>? _positionStreamSubscription;


  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _setupLocationTracking();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        _driver = await FirestoreService.instance.getDriverData(user.uid);
        if (_driver != null) {
          setState(() {
            _isOnline = _driver?.workStatus == WorkStatus.online;
          });
          // Load current trip
          final activeTripsQuery = await FirestoreService.instance
              .getFutureDataWithTwoCondition('trips',
                  condition1: "status",
                  condition2: "driverId",
                  value1: "active",
                  value2: user.uid);

          if (activeTripsQuery.docs.isNotEmpty) {
            setState(() {
              _currentTrip = Trip.fromMap(activeTripsQuery.docs.first.data());
              _startLocationTracking();
            });
          } else {

            final pendingTripsQuery = await FirestoreService.instance
                .getFutureDataWithTwoCondition('trips',
                condition2: "driverId",value2: _driver?.id,
                    condition1: "status",
                    value1: "pending");

            setState(() {
              _pendingTrips = pendingTripsQuery.docs
                  .map((doc) => Trip.fromMap(doc.data()))
                  .toList();
            });                     


          }

          if (_currentTrip?.busId != null) {
            final busDoc = await FirestoreService.instance
                .getSpecficData('buses', _currentTrip?.busId ?? '');
            if (busDoc.exists) {
              setState(() {
                _assignedBus = Bus.fromMap(busDoc.data()!);
              });
            }
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')));
    }
  }



  Future<void> _setupLocationTracking() async {
    
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are required')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      if (_currentTrip != null && _currentTrip!.status == 'active') {
    }
  }

  void _startLocationTracking() async {
    try {
      print("start");
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Update when user moves 10 meters
        ),
      ).listen(
        (Position position) async {
          if (_currentTrip != null) {
            try {
              await FirestoreService.instance.updateDocument(
                collection: 'buses',
                documentId: _currentTrip!.busId!,
                data: {
                  'currentLocation': GeoPoint(
                    position.latitude,
                    position.longitude,
                  ),
                },
              );
            } catch (e) {
              debugPrint('Error updating location: $e');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }



  Future<void> _toggleOnlineStatus(bool value) async {
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await FirestoreService.instance.updateDocument(
          collection: 'users',
          documentId: user.uid,
          data: {
            'workStatus':
                value ? WorkStatus.online.name : WorkStatus.offline.name,
          },
        );
        setState(() {
          _isOnline = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Status updated to ${value ? 'Online' : 'Offline'}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.toString()}')));
    }
  }

  
  Future<void> _reportBusMalfunction() async {
    final TextEditingController _issueController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();
    String _selectedSeverity = 'Medium';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Bus Malfunction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _issueController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'e.g., Brake failure, Engine overheating',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide details about the issue',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items:
                    ['Low', 'Medium', 'High', 'Critical'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  _selectedSeverity = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_issueController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter an issue title')));
                return;
              }

              try {
                final user = AuthService.instance.currentUser;
                if (user != null && _assignedBus != null) {
                  await FirestoreService.instance.createDocumentWithData(
                      collection: 'bus_malfunctions',
                      data: {
                        'busId': _assignedBus!.id,
                        'driverId': user.uid,
                        'issue': _issueController.text,
                        'description': _descriptionController.text,
                        'severity': _selectedSeverity,
                        'status': 'reported',
                        'timestamp': DateTime.now(),
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Malfunction reported successfully')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('Failed to report malfunction: ${e.toString()}')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Driver Dashboard',
            style: TextStyle(color: Color(0xFF0072ff))),
      ),
      body: _driver == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue[50]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _loadDriverData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Driver Status Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Driver Status',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Online Status'),
                                subtitle: Text(_isOnline
                                    ? 'You are online and available'
                                    : 'You are offline'),
                                value: _isOnline,
                                activeColor: Colors.green,
                                onChanged: _toggleOnlineStatus,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                  
                      // Current Route Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Current Route',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_pendingTrips.isNotEmpty && _currentTrip == null)
                                Column(
                                  children: [
                                    const Text('Available Trips',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _pendingTrips.length,
                                      itemBuilder: (context, index) {
                                        final trip = _pendingTrips[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text('Trip #${trip.id}'),
                                            subtitle: Text(
                                                'From: ${trip.stations?.first.name} to ${trip.stations?.last.name}'),
                                            trailing: ElevatedButton(
                                              onPressed: _isOnline
                                                  ? () async {
                                                      try {
                                                        await FirestoreService
                                                            .instance
                                                            .updateDocument(
                                                          collection: 'trips',
                                                          documentId: trip.id!,
                                                          data: {
                                                            'status': 'active',
                                                            'driverId':
                                                                _driver?.id,
                                                          },
                                                        );
                                                        setState(() {
                                                          _currentTrip = trip;
                                                          _pendingTrips
                                                              .remove(trip);
                                                          _startLocationTracking();
                                                          _loadDriverData();
                                                        });
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text(
                                                                  'Trip accepted successfully')),
                                                        );
                                                      } catch (e) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'Failed to accept trip: ${e.toString()}')),
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF0072ff),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Accept'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                              else if (_currentTrip != null)
                                Column(
                                  children: [
                                    ListTile(
                                      title: const Text('Active Trip'),
                                      subtitle: Text('From: ${_currentTrip!.stations?.first.name} to ${_currentTrip!.stations?.last.name} '),
                                      trailing: const Icon(Icons.route,color: Color(0xFF0072ff),),
                                      onTap: () {
                                        // Navigate to map view
                                      },
                                    ),
                                    const Divider(),
                                    const Text(
                                      'Bus Stops',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_currentTrip!.stations!.isEmpty)
                                      const Text('No stops assigned yet')
                                    else
                                      SizedBox(
                                        height: 80,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: List.generate(
                                              _currentTrip!.stations?.length ?? 0,
                                              (index) {
                                                final station = _currentTrip!.stations?[index];
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor: Colors.blue.shade100,
                                                        child: Text('${index + 1}'),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        station?.name ?? "",
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              else
                                const ListTile(
                                  leading: Icon(Icons.info),
                                  title: Text('No active route'),
                                  subtitle:
                                      Text('Wait for admin to assign a route'),
                                ),
                                if (_currentTrip != null && _currentTrip!.status == 'active')
                                  Column(crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Trip Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                       const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await FirestoreService.instance.updateDocument(
                                                collection: 'trips',
                                                documentId: _currentTrip!.id!,
                                                data: {'status': 'finished'},
                                              );
                                              _positionStreamSubscription?.cancel();
                                              setState(() {
                                                _currentTrip = null;
                                                _assignedBus = null;
                                                _positionStreamSubscription?.cancel();

                                              });
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Trip finished successfully')),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Error finishing trip: ${e.toString()}')),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Finish Trip'),
                                        ),
                                    ],
                                  )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Statistics Card
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Today\'s Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      color: Colors.blue[50],
                                      child: const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Icon(Icons.people,
                                                size: 32, color: Colors.blue),
                                            SizedBox(height: 8),
                                            Text('Total Students'),
                                            Text(
                                              '0',
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Card(
                                      color: Colors.green[50],
                                      child: const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Icon(Icons.route,
                                                size: 32, color: Colors.green),
                                            SizedBox(height: 8),
                                            Text('Trips Completed'),
                                            Text(
                                              '0',
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bus Malfunction Reporting
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bus Status',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_assignedBus != null)
                                ListTile(
                                  title:
                                      Text('Bus #${_assignedBus!.busNumber}'),
                                  subtitle: Text(
                                      'Capacity: ${_assignedBus!.capacity} seats'),
                                  trailing: ElevatedButton.icon(
                                    icon: const Icon(Icons.report_problem),
                                    label: const Text('Report Issue'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _reportBusMalfunction,
                                  ),
                                )
                              else
                                const ListTile(
                                  leading: Icon(Icons.directions_bus),
                                  title: Text('No bus assigned'),
                                  subtitle:
                                      Text('Contact admin for bus assignment'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
