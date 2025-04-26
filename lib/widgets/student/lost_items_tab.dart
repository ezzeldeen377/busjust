import 'package:flutter/material.dart';

class LostItemsTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Future<void> Function() onSubmit;
  final Color primaryColor;
  final double borderRadius;
  final Widget Function({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hintText,
    TextInputType keyboardType,
    int maxLines,
  }) buildTextField;

  const LostItemsTab({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.onSubmit,
    required this.primaryColor,
    required this.borderRadius,
    required this.buildTextField,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: primaryColor,
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
                borderRadius: BorderRadius.circular(borderRadius),
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
                  buildTextField(
                    controller: nameController,
                    label: 'Item Name',
                    prefixIcon: Icons.inventory_2_rounded,
                    hintText: 'What did you lose?',
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: descriptionController,
                    label: 'Description',
                    prefixIcon: Icons.description_rounded,
                    hintText: 'Provide details about the lost item...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}