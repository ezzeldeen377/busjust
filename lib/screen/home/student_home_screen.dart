import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/driver.dart';
import 'package:bus_just/models/lost_item.dart';
import 'package:bus_just/models/route_update.dart';
import 'package:bus_just/models/student.dart';
import 'package:bus_just/models/feedback.dart' as bus_feedback;
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/router/routes.dart';
import 'package:bus_just/services/bus_tracking_service.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:bus_just/services/notification_service.dart';
import 'package:bus_just/services/student_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  final Student student;

  const StudentHomeScreen({super.key, required this.student});

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentService _studentService = StudentService.instance;
  final BusTrackingService _busTrackingService = BusTrackingService.instance;

  // Define constants for consistent styling
  final Color _primaryColor = const Color(0xFF0072ff);
  final Color _secondaryColor = const Color(0xFF00c6ff);
  final double _borderRadius = 12.0;

  // State variables
  Trip? selectedTrip;
  DateTime? _estimatedArrivalTime;
  List<Trip> _availableTrips = [];
  List<RouteUpdate> _routeUpdates = [];
  bool _isLoading = true;
  Bus? _bus;
  String? _tripId;
  LatLng? _busLocation;

  // Form controllers
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _lostItemNameController = TextEditingController();
  final TextEditingController _lostItemDescController = TextEditingController();
  int _feedbackRating = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load available routes
      final tripData = await _studentService.getAvailabletTrips();
      if (tripData.isNotEmpty) {
        setState(() {
          _availableTrips = tripData.map((trip) => Trip.fromMap(trip)).toList();
        });
      }

      // Get student's selected route ID
      final studentData = await FirestoreService.instance
          .getSpecficData("users", widget.student.id);
      final studentSelectedRouteId = studentData.data()?['selectedRouteId'];
      print("studentSelectedRouteId: $studentSelectedRouteId");
      // If student has a selected route, find it in available trips
      if (studentSelectedRouteId != null && _availableTrips.isNotEmpty) {
        final selectedTripData = _availableTrips.firstWhere(
          (trip) =>
              trip.id == studentSelectedRouteId && trip.status == 'active',
          orElse: () => _availableTrips.first,
        );

        setState(() {
          selectedTrip = selectedTripData;
        });

        // Load bus info for the selected trip
        await _loadBusInfo();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<void> _loadBusInfo() async {
    try {
      // Get active trips for the selected route

      if (selectedTrip != null) {
        _tripId = selectedTrip?.id;
        final busData = await FirestoreService.instance
            .getSpecficData("buses", selectedTrip!.busId!);
        _bus = Bus.fromMap(busData.data()!);
        final busStops = selectedTrip?.stations;

        // Get estimated arrival time

        if (busStops!.isNotEmpty) {
          final nextStop = busStops.first;
          final eta = await _busTrackingService.getEstimatedArrivalTime(
              _bus!.currentLocation!, nextStop.point!);
          setState(() {
            _estimatedArrivalTime = eta;
          });
        }
        // Listen to bus location updates
        _busTrackingService
            .getBusLocationStream(_bus?.id ?? '')
            .listen((location) {
          setState(() {
            _busLocation = location;
          });
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading bus info: $e');
    }
  }

  // void _listenToRouteUpdates() {
  //   _notificationService.getRouteUpdatesStream(selectedTrip!).listen((updates) {
  //     setState(() {
  //       _routeUpdates = updates;
  //     });
  //   });
  // }

  Future<void> _selectRoute(Trip trip) async {
    try {
      await _studentService.selectRoute(widget.student.id, trip.id ?? "");
      setState(() {
        selectedTrip = trip;
      });
      await _loadBusInfo();
      _showSuccessSnackBar('Route selected successfully');
    } catch (e) {
      _showErrorSnackBar('Error selecting route: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.isEmpty) {
      _showErrorSnackBar('Please enter feedback message');
      return;
    }

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      final feedback = bus_feedback.Feedback(
        id: FirebaseFirestore.instance.collection('feedback').doc().id,
        studentId: widget.student.id,
        tripId: _tripId,
        routeId: selectedTrip?.id ?? '',
        message: _feedbackController.text,
        rating: _feedbackRating,
        timestamp: DateTime.now(),
        isResolved: false,
      );

      await _studentService.submitFeedback(feedback);
      _feedbackController.clear();
      _showSuccessSnackBar('Feedback submitted successfully');
    } catch (e) {
      _showErrorSnackBar('Error submitting feedback: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reportLostItem() async {
    if (_lostItemNameController.text.isEmpty ||
        _lostItemDescController.text.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      final lostItem = LostItem(
        id: FirebaseFirestore.instance.collection('lostItems').doc().id,
        studentId: widget.student.id,
        tripId: _tripId,
        busId: _bus?.id,
        itemName: _lostItemNameController.text,
        description: _lostItemDescController.text,
        reportDate: DateTime.now(),
        status: 'reported',
        imageUrl: null,
      );

      await _studentService.reportLostItem(lostItem);
      _lostItemNameController.clear();
      _lostItemDescController.clear();
      _showSuccessSnackBar('Lost item reported successfully');
    } catch (e) {
      _showErrorSnackBar('Error reporting lost item: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToMapScreen() {
    if (_busLocation != null && _tripId != null) {
      Navigator.pushNamed(
        context,
        Routes.map,
        arguments: {
          'busLocation': _busLocation,
          'tripId': _tripId,
          'stations': selectedTrip?.stations,
        },
      );
    } else {
      _showErrorSnackBar('Bus location not available');
    }
  }

  Future<void> _endTrip() async {
    try {
      // Update Firestore to set selectedRouteId to null
      await _studentService.endTrip(widget.student.id,);
      
      // Reset state variables
      setState(() {
        selectedTrip = null;
        _estimatedArrivalTime = null;
        _busLocation = null;
        _tripId = null;
        _bus = null;
      });
      
      _showSuccessSnackBar('Trip ended successfully');
    } catch (e) {
      _showErrorSnackBar('Error ending trip: $e');
    }
  }

  // Helper method to build consistent text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    _lostItemNameController.dispose();
    _lostItemDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0072ff)))
          : Column(
              children: [
                // Bus arrival card
                Padding(
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
                          Row(
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
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _estimatedArrivalTime != null
                                                      ? const Color(0xFF00C853).withOpacity(0.15)
                                                      : Colors.grey.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 14,
                                                      color: _estimatedArrivalTime != null
                                                          ? const Color(0xFF00C853)
                                                          : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _estimatedArrivalTime != null
                                                          ? '${_estimatedArrivalTime!.difference(DateTime.now()).inMinutes} mins'
                                                          : 'No active trips',
                                                      style: TextStyle(
                                                        color: _estimatedArrivalTime != null
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _busLocation != null
                                      ? _navigateToMapScreen
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0072ff),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.route_outlined, size: 16, color: Colors.white,),
                                  label: const Text('Track',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: selectedTrip != null
                                      ? _endTrip
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5252),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.white),
                                  label: const Text('End Trip',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF0072ff),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF0072ff),
                    tabs: const [
                      Tab(icon: Icon(Icons.map), text: 'Routes'),
                      Tab(icon: Icon(Icons.star), text: 'Feedback'),
                      Tab(icon: Icon(Icons.search), text: 'Lost Items'),
                      // Tab(icon: Icon(Icons.settings), text: 'Settings'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Routes Tab
                      _buildRoutesTab(),

                      // Feedback Tab
                      _buildFeedbackTab(),

                      // Lost Items Tab
                      _buildLostItemsTab(),

                      // Settings Tab
                      // _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRoutesTab() {
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
            child: _availableTrips.isEmpty
                ? const Center(child: Text('No routes available'))
                : ListView.builder(
                    itemCount: _availableTrips.length,
                    itemBuilder: (context, index) {
                      final trip = _availableTrips[index];
                      final isSelected = trip.id == selectedTrip?.id;

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
                            return const Center(child: Text('No active trips'));
                          }

                          final bus = snapshot.data!['bus'] as Bus;
                          final driver = snapshot.data!['driver'] as Driver;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                                            if (trip.stations != null &&
                                                trip.stations!.isNotEmpty)
                                              Expanded(
                                                // Prevents overflow inside the Row
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                              color:
                                                                  Colors.green,
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
                                                            trip.stations!.first
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
                                                    if (trip.stations!.length >
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
                                                                color:
                                                                    Colors.red,
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
                                                              trip
                                                                      .stations!
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
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        trip.status == 'active'
                                                            ? Colors.green[100]
                                                            : Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    trip.status
                                                            ?.toUpperCase() ??
                                                        'N/A',
                                                    style: TextStyle(
                                                      color: trip.status ==
                                                              'active'
                                                          ? Colors.green[900]
                                                          : Colors.grey[900],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: trip.status == 'active'
                                          ? () => _selectRoute(trip)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0072ff),
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('Book Trip'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: _primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Submit Feedback',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rate_review_rounded,
                        color: _primaryColor,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'How would you rate your experience?',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          onPressed: () {
                            setState(() {
                              _feedbackRating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < _feedbackRating
                                ? Icons.star
                                : Icons.star_border,
                            color: index < _feedbackRating
                                ? Colors.amber
                                : Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _feedbackController,
                    label: 'Your Feedback',
                    prefixIcon: Icons.comment_rounded,
                    hintText: 'Tell us about your experience...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Submit Feedback',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLostItemsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Report Lost Item',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _lostItemNameController,
                    label: 'Item Name',
                    prefixIcon: Icons.inventory_2_rounded,
                    hintText: 'What did you lose?',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lostItemDescController,
                    label: 'Description',
                    prefixIcon: Icons.description_rounded,
                    hintText: 'Provide details about the item...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement image upload
                          },
                          icon: const Icon(Icons.photo_camera, color: Colors.black87, size: 20),
                          label: const Text(
                            'Add Photo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_borderRadius),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _reportLostItem,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: const Text(
                            'Report',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_borderRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
