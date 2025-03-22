import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/lost_item.dart';
import 'package:bus_just/models/route_update.dart';
import 'package:bus_just/models/student.dart';
import 'package:bus_just/models/feedback.dart' as bus_feedback;
import 'package:bus_just/router/routes.dart';
import 'package:bus_just/services/bus_tracking_service.dart';
import 'package:bus_just/services/notification_service.dart';
import 'package:bus_just/services/student_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class EnhancedStudentHomeScreen extends StatefulWidget {
  final Student student;

  const EnhancedStudentHomeScreen({super.key, required this.student});

  @override
  _EnhancedStudentHomeScreenState createState() => _EnhancedStudentHomeScreenState();
}

class _EnhancedStudentHomeScreenState extends State<EnhancedStudentHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentService _studentService = StudentService.instance;
  final BusTrackingService _busTrackingService = BusTrackingService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  
  // State variables
  String? _selectedRouteId;
  DateTime? _estimatedArrivalTime;
  List<Map<String, dynamic>> _availableRoutes = [];
  List<RouteUpdate> _routeUpdates = [];
  bool _isLoading = true;
  String? _busId;
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
    _tabController = TabController(length: 4, vsync: this);
    _loadStudentData();
  }
  
  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load student's preferred route
      _selectedRouteId = widget.student.preferredBusRoute;
      
      // Load available routes
      _availableRoutes = await _studentService.getAvailableRoutes(widget.student.id);
      
      // If student has a preferred route, get bus info and updates
      if (_selectedRouteId != null) {
        await _loadBusInfo();
        _listenToRouteUpdates();
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
      final trips = await _busTrackingService.getActiveTripsForRoute(_selectedRouteId!).first;
      
      if (trips.isNotEmpty) {
        final trip = trips.first;
        _tripId = trip.id;
        _busId = trip.busId;
        
        // Get estimated arrival time
        final busStops = await _busTrackingService.getBusStopsForTrip(_tripId!);
        if (busStops.isNotEmpty) {
          final nextStop = busStops.first;
          final eta = await _busTrackingService.getEstimatedArrivalTime(_tripId!, nextStop.id);
          setState(() {
            _estimatedArrivalTime = eta;
          });
        }
        
        // Listen to bus location updates
        _busTrackingService.getBusLocationStream(_tripId!).listen((location) {
          setState(() {
            _busLocation = location;
          });
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading bus info: $e');
    }
  }
  
  void _listenToRouteUpdates() {
    _notificationService.getRouteUpdatesStream(_selectedRouteId!).listen((updates) {
      setState(() {
        _routeUpdates = updates;
      });
    });
  }
  
  Future<void> _selectRoute(String routeId) async {
    try {
      await _studentService.selectRoute(widget.student.id, routeId);
      setState(() {
        _selectedRouteId = routeId;
      });
      await _loadBusInfo();
      _listenToRouteUpdates();
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
        routeId: _selectedRouteId,
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
    if (_lostItemNameController.text.isEmpty || _lostItemDescController.text.isEmpty) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }
    
    try {
      final lostItem = LostItem(
        id: FirebaseFirestore.instance.collection('lostItems').doc().id,
        studentId: widget.student.id,
        tripId: _tripId,
        busId: _busId,
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0072ff)))
          : Column(
              children: [
                // Bus arrival card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.directions_bus, color: Color(0xFF0072ff), size: 28),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Next Bus Arrival',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        _estimatedArrivalTime != null
                                            ? 'ETA: ${DateFormat.jm().format(_estimatedArrivalTime!)}'
                                            : 'No active trips',
                                        style: TextStyle(
                                          color: _estimatedArrivalTime != null ? Colors.green[700] : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _busLocation != null ? _navigateToMapScreen : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0072ff),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Track'),
                              ),
                            ],
                          ),
                          if (_routeUpdates.isNotEmpty) ...[  
                            const Divider(height: 24),
                            const Text(
                              'Latest Updates',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                  Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _routeUpdates.first.message,
                                      style: TextStyle(color: Colors.amber[900]),
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
                      Tab(icon: Icon(Icons.notifications), text: 'Updates'),
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
                      
                      // Updates Tab
                      _buildUpdatesTab(),
                      
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
            child: _availableRoutes.isEmpty
                ? const Center(child: Text('No routes available'))
                : ListView.builder(
                    itemCount: _availableRoutes.length,
                    itemBuilder: (context, index) {
                      final route = _availableRoutes[index];
                      final isSelected = route['id'] == _selectedRouteId;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: isSelected ? 4 : 1,
                        child: InkWell(
                          onTap: () => _selectRoute(route['id']),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: const Color(0xFF0072ff), width: 2)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      route['name'] ?? 'Unnamed Route',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0072ff),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Selected',
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'From: ${route['startLocation'] ?? 'Unknown'} - To: ${route['endLocation'] ?? 'Unknown'}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Schedule: ${route['schedule'] ?? 'Not specified'}',
                                  style: TextStyle(color: Colors.grey[700]),
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
  
  Widget _buildUpdatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Updates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _routeUpdates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No updates available'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _routeUpdates.length,
                    itemBuilder: (context, index) {
                      final update = _routeUpdates[index];
                      final isNew = !update.isRead;
                      
                      return Dismissible(
                        key: Key(update.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _notificationService.markNotificationAsRead(update.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: isNew ? 3 : 1,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: isNew
                                  ? Border.all(color: Colors.amber[700]!, width: 1)
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: isNew ? Colors.amber[700] : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM dd, yyyy - h:mm a').format(update.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isNew)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.amber[300]!),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: TextStyle(fontSize: 10, color: Colors.amber[800]),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  update.message,
                                  style: const TextStyle(fontSize: 14),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            index < _feedbackRating ? Icons.star : Icons.star_border,
                            color: index < _feedbackRating ? Colors.amber : Colors.grey,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0072ff), width: 2),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0072ff), width: 2),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF0072ff), width: 2),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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