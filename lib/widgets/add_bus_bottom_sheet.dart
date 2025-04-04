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
  
  // Define constants for consistent styling
  final Color _primaryColor = const Color(0xFF0072ff);
  final Color _secondaryColor = const Color(0xFF00c6ff);
  final double _borderRadius = 12.0;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(_borderRadius * 2),
          topRight: Radius.circular(_borderRadius * 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  color: _primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add New Bus',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _busNameController,
              label: 'Bus Name',
              prefixIcon: Icons.label_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter bus name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _busNumberController,
              label: 'Bus Number',
              prefixIcon: Icons.numbers_rounded,
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
            _buildTextField(
              controller: _capacityController,
              label: 'Capacity',
              prefixIcon: Icons.people_alt_rounded,
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
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_borderRadius),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade50,
              ),
              child: SwitchListTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.power_settings_new_rounded,
                      color: _isActive ? _primaryColor : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bus Active Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                value: _isActive,
                activeColor: _primaryColor,
                activeTrackColor: _secondaryColor.withOpacity(0.5),
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addBus,
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
                'Add Bus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            ],
          ),
        ),
      );
  }
  
  // Helper method to build consistent text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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