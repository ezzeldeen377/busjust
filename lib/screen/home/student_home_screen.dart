import 'package:bus_just/models/bus.dart';
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
  _StudentHomeScreenState createState() =>
      _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentService _studentService = StudentService.instance;
  final BusTrackingService _busTrackingService = BusTrackingService.instance;
  final NotificationService _notificationService = NotificationService.instance;

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
      final studentData = await FirestoreService.instance.getSpecficData(
          "users", widget.student.id);
      final studentSelectedRouteId = studentData.data()?['selectedRouteId'];
      print("studentSelectedRouteId: $studentSelectedRouteId");
      // If student has a selected route, find it in available trips
      if (studentSelectedRouteId != null && _availableTrips.isNotEmpty) {
        final selectedTripData = _availableTrips.firstWhere(
          (trip) => trip.id == studentSelectedRouteId&&trip.status=='active',
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
        final busData =
            await FirestoreService.instance.getSpecficData("buses", selectedTrip!.busId!);
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
        _busTrackingService.getBusLocationStream( _bus?.id??'').listen((location) {
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
    }
  }

  Future<void> _reportLostItem() async {
    if (_lostItemNameController.text.isEmpty ||
        _lostItemDescController.text.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    try {
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
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0072ff).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.directions_bus,
                                        color: Color(0xFF0072ff), size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Bus Arrival',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            letterSpacing: -0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _estimatedArrivalTime != null
                                            ? 'ETA: ${DateFormat.jm().format(_estimatedArrivalTime!)}'
                                            : 'No active trips',
                                        style: TextStyle(
                                          color: _estimatedArrivalTime != null
                                              ? const Color(0xFF00C853)
                                              : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _busLocation != null
                                    ? _navigateToMapScreen
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0072ff),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Track',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          if (_routeUpdates.isNotEmpty) ...[
                            const Divider(height: 24),
                            const Text(
                              'Latest Updates',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.amber[800], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _routeUpdates.first.message,
                                      style:
                                          TextStyle(color: Colors.amber[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                      final isSelected = trip.id == selectedTrip;

                      return Card(
  margin: const EdgeInsets.only(bottom: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  elevation: isSelected ? 8 : 2,
  color: Colors.white,
  child: InkWell(
    onTap: () => _selectRoute(trip),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF0072ff), width: 2) : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Trip ID and Selected Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _bus?.busName?? 'Unknown',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF0072ff), size: 24),
            ],
          ),
          const SizedBox(height: 12),

          /// Route Information
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.stations?.first.name ?? 'Unknown',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trip.stations?.last.name ?? 'Unknown',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        
          const SizedBox(height: 12),

          /// Status and Available Seats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status: ${trip.status ?? 'Not specified'}',
                style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
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
            const Text(
              'Submit Feedback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How would you rate your experience?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                    const SizedBox(height: 16),
                    const Text(
                      'Your feedback',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell us about your experience...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF0072ff), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0072ff),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Submit Feedback'),
                      ),
                    ),
                  ],
                ),
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
            const Text(
              'Report Lost Item',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lostItemNameController,
                      decoration: InputDecoration(
                        hintText: 'What did you lose?',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF0072ff), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _lostItemDescController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Provide details about the item...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF0072ff), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement image upload
                            },
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Add Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reportLostItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0072ff),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Report'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
