import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/trip.dart';
import 'package:intl/intl.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Driver? _driver;
  Bus? _assignedBus;
  Trip? _currentTrip;
  bool _isOnline = false;
  bool _isOnShift = false;
  DateTime? _shiftStartTime;
  DateTime? _shiftEndTime;
  List<Map<String, dynamic>> _busStops = [];
  List<Map<String, dynamic>> _routeUpdates = [];
  
  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }
  
  Future<void> _loadDriverData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final driverDoc = await _firestore.collection('users').doc(user.uid).get();
        if (driverDoc.exists) {
          setState(() {
            _driver = Driver.fromMap(driverDoc.data()! as Map<String, dynamic>);
            _isOnline = _driver?.workStatus == WorkStatus.online;
          });
          
          // Load assigned bus
          if (_driver?.assignedBus != null) {
            final busDoc = await _firestore.collection('buses').doc(_driver!.assignedBus).get();
            if (busDoc.exists) {
              setState(() {
                _assignedBus = Bus.fromMap(busDoc.data()! as Map<String, dynamic>);
              });
            }
          }
          
          // Load current trip
          final tripQuery = await _firestore.collection('trips')
              .where('driverId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();
          
          if (tripQuery.docs.isNotEmpty) {
            setState(() {
              _currentTrip = Trip.fromMap(tripQuery.docs.first.data());
            });
            _loadBusStops();
          }
          
          // Load route updates
          _loadRouteUpdates();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}'))
      );
    }
  }
  
  Future<void> _loadBusStops() async {
    if (_currentTrip == null) return;
    
    try {
      final stopsQuery = await _firestore.collection('bus_stops')
          .where('tripId', isEqualTo: _currentTrip!.id)
          .orderBy('sequence')
          .get();
      
      setState(() {
        _busStops = stopsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] as String,
            'studentCount': data['studentCount'] as int,
            'location': data['location'] as GeoPoint,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading bus stops: ${e.toString()}');
    }
  }
  
  Future<void> _loadRouteUpdates() async {
    if (_driver == null) return;
    
    try {
      final updatesQuery = await _firestore.collection('route_updates')
          .where('driverId', isEqualTo: _driver!.id)
          .where('isRead', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();
      
      setState(() {
        _routeUpdates = updatesQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'message': data['message'] as String,
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
            'isRead': data['isRead'] as bool,
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading route updates: ${e.toString()}');
    }
  }
  
  Future<void> _toggleOnlineStatus(bool value) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'workStatus': value ? WorkStatus.online.toString() : WorkStatus.offline.toString(),
        });
        
        setState(() {
          _isOnline = value;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${value ? 'Online' : 'Offline'}'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e.toString()}'))
      );
    }
  }
  
  Future<void> _toggleShiftStatus(bool value) async {
    final now = DateTime.now();
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (value) {
          // Starting shift
          final shiftDoc = await _firestore.collection('shifts').add({
            'driverId': user.uid,
            'startTime': now,
            'endTime': null,
            'status': 'active',
          });
          
          setState(() {
            _isOnShift = true;
            _shiftStartTime = now;
            _shiftEndTime = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift started successfully'))
          );
        } else {
          // Ending shift
          final shiftsQuery = await _firestore.collection('shifts')
              .where('driverId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'active')
              .limit(1)
              .get();
          
          if (shiftsQuery.docs.isNotEmpty) {
            await _firestore.collection('shifts').doc(shiftsQuery.docs.first.id).update({
              'endTime': now,
              'status': 'completed',
              'duration': now.difference(_shiftStartTime!).inMinutes,
            });
            
            setState(() {
              _isOnShift = false;
              _shiftEndTime = now;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shift ended successfully'))
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update shift: ${e.toString()}'))
      );
    }
  }
  
  Future<void> _reportBusMalfunction() async {
    final TextEditingController _issueController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
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
                items: ['Low', 'Medium', 'High', 'Critical'].map((String value) {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an issue title'))
                );
                return;
              }
              
              try {
                final user = _auth.currentUser;
                if (user != null && _assignedBus != null) {
                  await _firestore.collection('bus_malfunctions').add({
                    'busId': _assignedBus!.id,
                    'driverId': user.uid,
                    'issue': _issueController.text,
                    'description': _descriptionController.text,
                    'severity': _selectedSeverity,
                    'status': 'reported',
                    'timestamp': DateTime.now(),
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Malfunction reported successfully'))
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to report malfunction: ${e.toString()}'))
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _markUpdateAsRead(String updateId) async {
    try {
      await _firestore.collection('route_updates').doc(updateId).update({
        'isRead': true,
      });
      
      setState(() {
        _routeUpdates.removeWhere((update) => update['id'] == updateId);
      });
    } catch (e) {
      print('Error marking update as read: ${e.toString()}');
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: const Color(0xFF0072ff),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverData,
          ),
        ],
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
                                subtitle: Text(_isOnline ? 'You are online and available' : 'You are offline'),
                                value: _isOnline,
                                activeColor: Colors.green,
                                onChanged: _toggleOnlineStatus,
                              ),
                              const Divider(),
                              // Shift Management
                              SwitchListTile(
                                title: const Text('Shift Status'),
                                subtitle: Text(_isOnShift 
                                    ? 'Shift started at ${_formatDateTime(_shiftStartTime!)}' 
                                    : 'Start your shift when ready'),
                                value: _isOnShift,
                                activeColor: Colors.green,
                                onChanged: _toggleShiftStatus,
                              ),
                              if (_shiftStartTime != null && _shiftEndTime != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 8),
                                  child: Text(
                                    'Last shift: ${_formatDateTime(_shiftStartTime!)} to ${_formatDateTime(_shiftEndTime!)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Route Updates Card
                      if (_routeUpdates.isNotEmpty)
                        Card(
                          elevation: 2,
                          color: Colors.amber[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.notifications_active, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Route Updates',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_routeUpdates.length} new',
                                      style: const TextStyle(color: Colors.orange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ..._routeUpdates.map((update) => Dismissible(
                                  key: Key(update['id']),
                                  background: Container(
                                    color: Colors.green,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.check, color: Colors.white),
                                  ),
                                  onDismissed: (_) => _markUpdateAsRead(update['id']),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(update['message']),
                                      subtitle: Text(_formatDateTime(update['timestamp'])),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.check_circle_outline),
                                        onPressed: () => _markUpdateAsRead(update['id']),
                                      ),
                                    ),
                                  ),
                                )).toList(),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Route',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_currentTrip != null)
                                Column(
                                  children: [
                                    ListTile(
                                      title: const Text('Active Trip'),
                                      subtitle: Text('From: (${_currentTrip!.startPoint.latitude}, ${_currentTrip!.startPoint.longitude})\nTo: (${_currentTrip!.endPoint.latitude}, ${_currentTrip!.endPoint.longitude})'),
                                      trailing: const Icon(Icons.map),
                                      onTap: () {
                                        // Navigate to map view
                                      },
                                    ),
                                    const Divider(),
                                    const Text(
                                      'Bus Stops',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_busStops.isEmpty)
                                      const Text('No stops assigned yet')
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _busStops.length,
                                        itemBuilder: (context, index) {
                                          final stop = _busStops[index];
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blue,
                                              child: Text('${index + 1}'),
                                            ),
                                            title: Text(stop['name']),
                                            trailing: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.people, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${stop['studentCount']}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                )
                              else
                                const ListTile(
                                  leading: Icon(Icons.info),
                                  title: Text('No active route'),
                                  subtitle: Text('Wait for admin to assign a route'),
                                ),
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.people, size: 32, color: Colors.blue),
                                            const SizedBox(height: 8),
                                            const Text('Total Students'),
                                            Text(
                                              '${_busStops.fold(0, (sum, stop) => sum + (stop['studentCount'] as int))}',
                                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                                            Icon(Icons.route, size: 32, color: Colors.green),
                                            SizedBox(height: 8),
                                            Text('Trips Completed'),
                                            Text(
                                              '0',
                                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          padding: const EdgeInsets.all(16.0),
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
                                  title: Text('Bus #${_assignedBus!.registrationNumber}'),
                                  subtitle: Text('Capacity: ${_assignedBus!.capacity} seats'),
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
                                  subtitle: Text('Contact admin for bus assignment'),
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
