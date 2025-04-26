import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/lost_item.dart';
import 'package:bus_just/models/student.dart';
import 'package:bus_just/models/feedback.dart' ;
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/router/routes.dart';
import 'package:bus_just/services/bus_tracking_service.dart';
import 'package:bus_just/services/student_service.dart';
import 'package:bus_just/widgets/student/bus_arrival_card.dart';
import 'package:bus_just/widgets/student/feedback_tab.dart';
import 'package:bus_just/widgets/student/lost_items_tab.dart';
import 'package:bus_just/widgets/student/routes_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StudentHomeScreen extends StatefulWidget {
  final Student student;

  const StudentHomeScreen({super.key, required this.student});

  @override
  _StudentHomeScreenState createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BusTrackingService _busTrackingService = BusTrackingService.instance;

  // Define constants for consistent styling
  final Color _primaryColor = const Color(0xFF0072ff);
  final double _borderRadius = 12.0;

  // State variables
  Trip? selectedTrip;
  DateTime? _estimatedArrivalTime;
  List<Trip> _availableTrips = [];
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
      final tripData = await StudentService.getAvailabletTrips();
      if (tripData.isNotEmpty) {
        setState(() {
          _availableTrips = tripData.map((trip) => Trip.fromMap(trip)).toList();
        });
      }

      // Get student's selected route ID
      final studentData = await StudentService.getStudentData(widget.student.id);
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
    final busData = await StudentService.getBusData(selectedTrip!.busId!);
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

  Future<void> _selectRoute(Trip trip) async {
    try {
      await StudentService.selectRoute(widget.student.id, trip.id ?? "");
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
      
      final feedback = FeedbackModel(
            id: FirebaseFirestore.instance.collection('feedback').doc().id,
            isResolved: false,
            message: _feedbackController.text,
            rating: _feedbackRating,
            routeId: selectedTrip?.id ?? '',
            studentId: widget.student.id,
            studentName: widget.student.fullName ?? '',
            timestamp: DateTime.now(),
            tripId: _tripId ?? '',
          );

      await StudentService.submitFeedback(feedback);
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

      await StudentService.reportLostItem(lostItem);
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
          'tripId': _bus?.id,
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
      await StudentService.endTrip(widget.student.id,);
      
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
                BusArrivalCard(
                  estimatedArrivalTime: _estimatedArrivalTime,
                  selectedTrip: selectedTrip,
                  busLocation: _busLocation,
                  onTrackPressed: _navigateToMapScreen,
                  onEndTripPressed: _endTrip,
                ),
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
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RoutesTab(
                        availableTrips: _availableTrips,
                        selectedTrip: selectedTrip,
                        onRouteSelected: _selectRoute,
                      ),
                         FeedbackTab(
                          onRatingChanged: (rating) {
                          setState(() {
                            _feedbackRating = rating.toInt();
                          });
                        },
                        rating: _feedbackRating.toDouble(),
                        feedbackController: _feedbackController,
                        onSubmitFeedback: _submitFeedback,
                        primaryColor: const Color(0xFF0072ff),
                        borderRadius: _borderRadius,
                      ),
                                      LostItemsTab(
                        nameController: _lostItemNameController,
                        descriptionController: _lostItemDescController,
                        onSubmit: _reportLostItem,
                        primaryColor: _primaryColor,
                        borderRadius: _borderRadius,
                        buildTextField: _buildTextField,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }




}
