import 'package:bus_just/models/admin.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/user.dart';
import 'package:bus_just/services/admin_service.dart';
import 'package:bus_just/services/driver_service.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:bus_just/services/student_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatefulWidget {
  final UserModel user;

  const TripHistoryScreen({super.key, required this.user});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  String _selectedFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  List<Trip> _trips = [];
  List<Trip> _filteredTrips = [];

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  Future<void> _loadTripHistory() async {
    setState(() {
      _isLoading = true;
    });
    List<Trip> trips=[];
    try {
      // Query parameters depend on user role
  

      if (widget.user.role == UserRole.student) {
        trips = await StudentService.getStudentTripHistory(widget.user.id);
      
      } else if (widget.user.role == UserRole.admin) {
               trips = await AdminService.getTripHistory();

      } else if (widget.user.role == UserRole.driver) {
        trips = await DriverService.getDriverTrips(widget.user.id);
      }

    

      
      // Sort trips by creation date (newest first)
      trips.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));

      setState(() {
        _trips = trips;
        _filteredTrips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading trip history: ${e.toString()}'))
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTrips = _trips.where((trip) {
        // Filter by status
        if (_selectedFilter != 'All' && trip.status != _selectedFilter.toLowerCase()) {
          return false;
        }

        // Filter by date range
        if (_startDate != null && trip.createdAt != null && trip.createdAt!.isBefore(_startDate!)) {
          return false;
        }
        if (_endDate != null && trip.createdAt != null && trip.createdAt!.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0072ff),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'All';
      _startDate = null;
      _endDate = null;
      _filteredTrips = _trips;
    });
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0072ff),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
          if (_selectedFilter != 'All' || _startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTrips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No trip history found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilter != 'All' || _startDate != null || _endDate != null
                            ? 'Try changing your filters'
                            : 'Your trips will appear here',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (_selectedFilter != 'All' || _startDate != null || _endDate != null)
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTripHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = _filteredTrips[index];
                      return _buildTripCard(trip);
                    },
                  ),
                ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final fromStation = trip.stations?.isNotEmpty == true ? trip.stations!.first.name : 'Unknown';
    final toStation = trip.stations?.isNotEmpty == true ? trip.stations!.last.name : 'Unknown';
    final formattedDate = trip.createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(trip.createdAt!)
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showTripDetails(trip);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade50,
                                        Colors.white,
                                      ],stops: const [0.1, 0.9],
                                    ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip #${trip.id?.substring(0, 6) ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(trip.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(trip.status)),
                    ),
                    child: Text(
                      trip.status?.toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        color: _getStatusColor(trip.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'From: $fromStation',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF0072ff), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To: $toStation',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  if (trip.distance != null)
                    Row(
                      children: [
                        const Icon(Icons.straighten, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(trip.distance! / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Filter Trips',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All', setState),
                      _filterChip('Active', setState),
                      _filterChip('Completed', setState),
                      _filterChip('Pending', setState),
                      _filterChip('Cancelled', setState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _selectDateRange(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate != null && _endDate != null
                                ? '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                                : 'Select date range',
                            style: TextStyle(
                              color: _startDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearFilters();
                        },
                        child: const Text('Clear All'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0072ff),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String label, StateSetter setState) {
    return FilterChip(
      selected: _selectedFilter == label,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? label : 'All';
        });
        // Don't apply filters immediately, wait for user to press Apply
      },
      selectedColor: const Color(0xFF0072ff).withOpacity(0.2),
      checkmarkColor: const Color(0xFF0072ff),
    );
  }

  void _showTripDetails(Trip trip) {
    final fromStation = trip.stations?.isNotEmpty == true ? trip.stations!.first.name : 'Unknown';
    final toStation = trip.stations?.isNotEmpty == true ? trip.stations!.last.name : 'Unknown';
    final formattedDate = trip.createdAt != null
        ? DateFormat('MMMM dd, yyyy • hh:mm a').format(trip.createdAt!)
        : 'Unknown date';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trip Details',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(trip.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(trip.status)),
                          ),
                          child: Text(
                            trip.status?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(
                              color: _getStatusColor(trip.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _detailItem('Trip ID', trip.id ?? 'Unknown'),
                    _detailItem('Date & Time', formattedDate),
                    _detailItem('From', fromStation!),
                    _detailItem('To', toStation!),
                    if (trip.distance != null)
                      _detailItem('Distance', '${(trip.distance! / 1000).toStringAsFixed(1)} km'),
                    if (trip.estimatedTimeMinutes != null)
                      _detailItem('Estimated Time', '${trip.estimatedTimeMinutes} minutes'),
                    _detailItem('Driver ID', trip.driverId ?? 'Unknown'),
                    _detailItem('Bus ID', trip.busId ?? 'Unknown'),
                    const SizedBox(height: 20),
                    if (trip.stations != null && trip.stations!.isNotEmpty) ...[  
                      const Text(
                        'Route Stations',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: trip.stations!.length,
                        itemBuilder: (context, index) {
                          final station = trip.stations![index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index == 0
                                  ? Colors.grey
                                  : index == trip.stations!.length - 1
                                      ? const Color(0xFF0072ff)
                                      : Colors.orange,
                              radius: 12,
                              child: Icon(
                                index == 0
                                    ? Icons.trip_origin
                                    : index == trip.stations!.length - 1
                                        ? Icons.location_on
                                        : Icons.circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            title: Text(station.name ?? 'Unknown Station'),
                            subtitle: station.point != null
                                ? Text(
                                    'Lat: ${station.point!.latitude.toStringAsFixed(4)}, Lng: ${station.point!.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}