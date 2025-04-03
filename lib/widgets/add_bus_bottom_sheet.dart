import 'package:bus_just/models/bus.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AddBusBottomSheet extends StatefulWidget {
  const AddBusBottomSheet({super.key});

  @override
  State<AddBusBottomSheet> createState() => _AddBusBottomSheetState();
}

class _AddBusBottomSheetState extends State<AddBusBottomSheet> {
   final _formKey = GlobalKey<FormState>();
  final _busNameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _busNumberController = TextEditingController();
  bool _isActive = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
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
                controller: _busNameController,
                decoration: const InputDecoration(
                  labelText: 'Bus Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                  labelText: 'Bus Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter bus number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
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
                activeColor: const Color(0xFF0072ff),
                onChanged: (bool value) {
                  setState(() {
                    print("@@@@@@@@@@$value");
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
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Bus'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
  }

  Future<void> _addBus() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a Bus model instance first

        // Add the bus model to Firestore
        final docRef = FirestoreService.instance.createEmptyDocumnet("buses");
        final bus = Bus(
          id: docRef.id,
          busName: _busNameController.text,
          busNumber: _busNumberController.text,
          capacity: int.parse(_capacityController.text),
          isActive: _isActive,
        );
        await docRef.set(bus.toMap());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus added successfully')),
        );

        setState(() {
          _isActive = true;
          _busNameController.clear();
          _busNumberController.clear();
          _capacityController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bus: $e')),
        );
      }
    }
  }
   @override
  void dispose() {
    _busNameController.dispose();
    _capacityController.dispose();
    _busNumberController.dispose();
    super.dispose();
  }
}