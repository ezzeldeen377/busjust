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
    
    // Define constants for consistent styling (matching add_bus_bottom_sheet.dart)
    final Color _primaryColor = const Color(0xFF0072ff);
    final Color _secondaryColor = const Color(0xFF00c6ff);
    final double _borderRadius = 12.0;

    // Helper method to build consistent text fields
    Widget _buildTextField({
      required TextEditingController controller,
      required String label,
      required IconData prefixIcon,
      String? hintText,
      TextInputType keyboardType = TextInputType.text,
      int? maxLines,
    }) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            labelStyle: TextStyle(color: Colors.grey.shade700),
            prefixIcon: Icon(prefixIcon, color: _primaryColor, size: 22),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_borderRadius),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          ),
        ),
      );
    }

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius * 2),
        ),
        elevation: 5,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_borderRadius * 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      child: Icon(
                        Icons.report_problem_rounded,
                        color: _primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Report Bus Malfunction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Form fields
                _buildTextField(
                  controller: _issueController,
                  label: 'Issue Title',
                  prefixIcon: Icons.warning_rounded,
                  hintText: 'e.g., Brake failure, Engine overheating',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  prefixIcon: Icons.description_rounded,
                  hintText: 'Provide details about the issue',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Dropdown for severity
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedSeverity,
                    decoration: InputDecoration(
                      labelText: 'Severity',
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      prefixIcon: Icon(Icons.priority_high_rounded, color: _primaryColor, size: 22),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
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
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                      // Driver Status Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Driver Status',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0072ff),
                                    ),
                                  ),
                                  Icon(
                                    _isOnline ? Icons.check_circle : Icons.cancel,
                                    color: _isOnline ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                title: const Text('Online Status'),
                                subtitle: Text(
                                  _isOnline
                                      ? 'You are online and available'
                                      : 'You are offline',
                                  style: TextStyle(
                                    color: _isOnline ? Colors.green : Colors.red,
                                  ),
                                ),
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
                        elevation: 6,
                        shadowColor: Colors.blue.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0072ff).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.route_rounded,
                                          color: Color(0xFF0072ff),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Current Route',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0072ff),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                             
                                ],
                              ),
                              const SizedBox(height: 20),
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
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Container(
    decoration: BoxDecoration(
gradient:  LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.blue.shade50,
                                    ],
                                  ),      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Details Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip #${trip.id?.substring(0, 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0072ff),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.stations?.first.name}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      '${trip.stations?.last.name}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Bus Image and Accept Button Section
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bus Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/bus.png',
                  height: 60,
                  width: 80,
                ),
              ),

              // Accept Button
              ElevatedButton(
                onPressed: _isOnline
                    ? () async {
                        try {
                          await FirestoreService.instance.updateDocument(
                            collection: 'trips',
                            documentId: trip.id!,
                            data: {
                              'status': 'active',
                              'driverId': _driver?.id,
                            },
                          );
                          setState(() {
                            _currentTrip = trip;
                            _pendingTrips.remove(trip);
                            _startLocationTracking();
                            _loadDriverData();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Trip accepted successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to accept trip: ${e.toString()}')),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072ff),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric( horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accept',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
                                      },
                                    ),
                                  ],
                                )
                              else if (_currentTrip != null)
                               FutureBuilder<Map<String, dynamic>>(
                          future: Future.wait([
                            FirestoreService.instance
                                .getStreamedData('buses')
                                .first
                                .then((snapshot) => snapshot.docs
                                    .firstWhere((doc) => doc.id == _currentTrip!.busId)
                                    .data() as Map<String, dynamic>),
                            FirestoreService.instance
                                .getStreamedData('users',
                                    condition: 'id', value: _currentTrip!.driverId)
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
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                             
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${bus.busName}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 100,
                                          height: 80,
                                          child: Image.asset(
                                              "assets/images/bus.png"),
                                        ),
                                      ],
                                    ),
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
                                          '${((_currentTrip?.distance??0)/1000).toStringAsFixed(1)} km',
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
                                          '${_currentTrip?.estimatedTimeMinutes ?? '0'} min',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                              color: Colors.grey[200]!),
                                        ),
                                      ),
                                      child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (_currentTrip?.stations != null &&
                                                  _currentTrip!.stations!.isNotEmpty)
                                                Expanded(
                                                  // Prevents overflow inside the Row
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 18,
                                                            height: 18,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .green[100],
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                color: Colors
                                                                    .green,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            // Ensures text does not overflow
                                                            child: Text(
                                                              _currentTrip
                                                                      ?.stations!
                                                                      .first
                                                                      .name ??
                                                                  'Starting Point',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (_currentTrip!.stations!
                                                              .length >
                                                          1)
                                                        Row(
                                                          children: [
                                                            Container(
                                                              width: 18,
                                                              height: 18,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .red[100],
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: Container(
                                                                decoration:
                                                                    const BoxDecoration(
                                                                  color: Colors
                                                                      .red,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              // Prevents overflow
                                                              child: Text(
                                                                _currentTrip
                                                                        ?.stations!
                                                                        .last
                                                                        .name ??
                                                                    'Destination',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              const SizedBox(
                                                  width:
                                                      8), // Adds spacing to prevent overflow
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _currentTrip?.status == 'active'
                                                      ? Colors.green[100]
                                                      : Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _currentTrip!.status?.toUpperCase() ??
                                                      'N/A',
                                                  style: TextStyle(
                                                    color:
                                                        _currentTrip!.status == 'active'
                                                            ? Colors.green[900]
                                                            : Colors.grey[900],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.grey),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'No active route',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Wait for admin to assign a route',
                                              style: TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_currentTrip != null && _currentTrip!.status == 'active')
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.green.shade300, Colors.green.shade100],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                                            SizedBox(width: 8),
                                            Text(
                                              'Trip Active',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.stop_circle_outlined),
                                        label: const Text('Finish Trip'),
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
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
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
                        color: Colors.white,
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
                        child: Container(
                          decoration: BoxDecoration(
                           gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      Colors.blue.shade50,
                                    ],
                                  ), 
                          ),
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
  // Helper Widgets
}