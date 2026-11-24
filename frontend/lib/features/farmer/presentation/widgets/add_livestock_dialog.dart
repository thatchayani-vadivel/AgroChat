import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';

/// Form dialog to add livestock or allied agricultural activities to a farm.
class AddLivestockDialog extends StatefulWidget {
  const AddLivestockDialog({super.key, required this.farmId});

  final int farmId;

  @override
  State<AddLivestockDialog> createState() => _AddLivestockDialogState();
}

class _AddLivestockDialogState extends State<AddLivestockDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _breedController;
  late TextEditingController _countController;
  late TextEditingController _purposeController;
  late TextEditingController _notesController;

  String _selectedCategory = 'Cattle';
  String _selectedHealthStatus = 'Healthy';

  final List<String> _categories = [
    'Cattle',
    'Buffalo',
    'Goat / Sheep',
    'Poultry / Chicken',
    'Dairy Farming',
    'Fishery / Aquaculture',
    'Beekeeping / Apiculture',
    'Sericulture',
  ];

  final List<String> _healthStatuses = [
    'Healthy',
    'Under Medication',
    'Vaccinated',
    'Quarantined',
  ];

  @override
  void initState() {
    super.initState();
    _breedController = TextEditingController();
    _countController = TextEditingController(text: '1');
    _purposeController = TextEditingController(text: 'Dairy / Milk');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _breedController.dispose();
    _countController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final count = int.tryParse(_countController.text.trim()) ?? 1;
    final livestock = LivestockModel(
      id: 0,
      farmId: widget.farmId,
      category: _selectedCategory,
      breedOrType: _breedController.text.trim().isEmpty
          ? null
          : _breedController.text.trim(),
      count: count,
      purpose: _purposeController.text.trim().isEmpty
          ? null
          : _purposeController.text.trim(),
      healthStatus: _selectedHealthStatus,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(livestock);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.pets_rounded, color: AppColors.primaryGreen),
          SizedBox(width: 8),
          Expanded(child: Text('Add Livestock / Allied Activity')),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Breed / Variety (Optional)',
                    hintText: 'e.g. Gir Cow, Murrah Buffalo, Osmanabadi Goat',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Count / Animal Quantity *',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Enter quantity (min 1)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Purpose',
                    hintText: 'e.g. Milk production, Breeding, Eggs',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedHealthStatus,
                  decoration: const InputDecoration(labelText: 'Health Status'),
                  items: _healthStatuses
                      .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedHealthStatus = val);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save Activity')),
      ],
    );
  }
}
