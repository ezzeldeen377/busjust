import 'package:bus_just/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/models/bus.dart';
import 'package:bus_just/models/trip.dart';
import 'package:bus_just/models/driver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_just/screen/map/route_selection_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isActive = true;

  @override
  void dispose() {
    _registrationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _showAddBusForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                'Add New Bus',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
               SizedBox(height: 16),
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter registration number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter capacity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Bus Active Status'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addBus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072ff),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Add Bus'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBus() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a Bus model instance first

        // Add the bus model to Firestore
        final docRef =  FirestoreService.instance.createEmptyDocumnet("buses");
        final bus = Bus(
          id: docRef.id,
          registrationNumber: _registrationController.text,
          capacity: int.parse(_capacityController.text),
          isActive: _isActive,
 
        );
        await docRef.set(bus.toMap());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus added successfully')),
        );

        _registrationController.clear();
        _capacityController.clear();

        setState(() {
          _isActive = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0072ff),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Trips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService.instance.getStreamedData("trips"),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No active trips'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final bus = Bus.fromMap(snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>);
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.route_outlined,
                              color: bus.isActive! ?const Color(0xFF0072ff) : Colors.grey,
                            ),
                            title: Text('Bus ${bus.registrationNumber}'),
                            subtitle: Text('Capacity: ${bus.capacity}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: bus.isActive! ? Colors.blue[100] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                bus.isActive! ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  color: bus.isActive! ? Colors.green[900] : Colors.grey[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bus Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddBusForm,
                  icon: const Icon(Icons.add,color: Colors.white,),
                  label: const Text('Add New Bus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0072ff),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:FirestoreService.instance.getStreamedData("buses"),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No buses available'),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 180, // Set a fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Change to horizontal scrolling
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final bus = Bus.fromMap(snapshot.data!.docs[index]
                              .data() as Map<String, dynamic>);
                          return Container(
                            width: 200, // Fixed width for each card
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_bus,
                                      color: bus.isActive! ? Colors.green : Colors.grey,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bus ${bus.registrationNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Capacity: ${bus.capacity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bus.isActive! ? Colors.green[100] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        bus.isActive! ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          color: bus.isActive! ? Colors.green[900] : Colors.grey[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registered Drivers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirestoreService.instance.getStreamedData("users",condition: "role",value: "driver"),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child:  CircularProgressIndicator());
                    }

                    // Replace the ListView.builder with a horizontal layout
                    return SizedBox(
                      height: 240, // Set a fixed height for the horizontal list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Change to horizontal scrolling
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final driver = Driver.fromMap(snapshot.data!.docs[index]
                              .data() as Map<String, dynamic>);
                          return SizedBox(
                            width: 200,
                            child: Card(
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircleAvatar(
                                      radius: 50,
                                      child: Icon(Icons.person, size: 50),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      driver.fullName ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      driver.email,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showAssignTripSheet(driver);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0072ff),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 30),
                                      ),
                                      child: const Text('Assign Trip'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create trip functionality
        },
        backgroundColor: const Color(0xFF0072ff),
        tooltip: 'Create New Trip',
        child: const Icon(Icons.add_location),
      ),
    );
  }
  // Add these methods after the _buildAdminCard method
  
  void _showAssignTripSheet(Driver driver) {
    Bus? selectedBus;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Trip to ${driver.fullName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Available Bus:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirestoreService.instance.getStreamedData("buses",condition: 'isActive',value: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Text('No active buses available');
                  }

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final bus = Bus.fromMap(
                            snapshot.data!.docs[index].data() as Map<String, dynamic>);
                        return RadioListTile<Bus>(
                          title: Text('Bus ${bus.registrationNumber}'),
                          subtitle: Text('Capacity: ${bus.capacity}'),
                          value: bus,
                          groupValue: selectedBus,
                          onChanged: (Bus? value) {
                            setState(() {
                              selectedBus = value;
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: selectedBus == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        _showRouteSelectionMap(driver, selectedBus!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0072ff),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Select Route on Map'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteSelectionMap(Driver driver, Bus bus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteSelectionScreen(
          driver: driver,
          bus: bus,
          onRouteSelected: (startPoint, endPoint) {
            _createTrip(driver, bus, startPoint, endPoint);
          },
        ),
      ),
    );
  }

  Future<void> _createTrip(
      Driver driver, Bus bus, LatLng startPoint, LatLng endPoint) async {
    try {
      // Create a new trip document
      final tripRef = FirestoreService.instance.createEmptyDocumnet("trips");
      
      final trip = {
        'id': tripRef.id,
        'driverId': driver.id,
        'busId': bus.id,
        'startPoint': GeoPoint(startPoint.latitude, startPoint.longitude),
        'endPoint': GeoPoint(endPoint.latitude, endPoint.longitude),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Update the bus with the current trip and driver
     FirestoreService.instance.updateDocument(collection: "buses", documentId: bus.id,data:  {
        'currentTripId': tripRef.id,
        'isActive': false,
      });
      // Create the trip
      await tripRef.set(trip);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip assigned successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error assigning trip: $e')),
      );
    }
  }
}