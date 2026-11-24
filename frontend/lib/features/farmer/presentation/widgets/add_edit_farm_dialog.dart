import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';

/// Form dialog to add a new farm or update an existing farm.
class AddEditFarmDialog extends StatefulWidget {
  const AddEditFarmDialog({super.key, this.existingFarm});

  final FarmModel? existingFarm;

  @override
  State<AddEditFarmDialog> createState() => _AddEditFarmDialogState();
}

class _AddEditFarmDialogState extends State<AddEditFarmDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _areaController;
  late TextEditingController _locationController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _waterSourceController;
  late TextEditingController _notesController;

  String _selectedSoilType = 'Black Cotton Soil';
  String _selectedIrrigationType = 'Drip Irrigation';
  String _selectedOwnership = 'Owned';

  final List<String> _soilTypes = [
    'Black Cotton Soil',
    'Alluvial Soil',
    'Red Soil',
    'Loamy Soil',
    'Sandy Loam',
    'Clay Soil',
    'Laterite Soil',
  ];

  final List<String> _irrigationTypes = [
    'Drip Irrigation',
    'Sprinkler Irrigation',
    'Canal Irrigation',
    'Rainfed',
    'Tube Well / Borewell',
    'Open Well / Pump',
  ];

  final List<String> _ownershipTypes = [
    'Owned',
    'Leased / Rented',
    'Sharecropped',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.existingFarm;
    _nameController = TextEditingController(text: f?.farmName ?? '');
    _areaController = TextEditingController(
      text: f != null ? f.totalAreaAcres.toString() : '',
    );
    _locationController = TextEditingController(text: f?.location ?? '');
    _districtController = TextEditingController(text: f?.district ?? '');
    _stateController = TextEditingController(
      text: f?.state.isNotEmpty == true ? f!.state : 'Maharashtra',
    );
    _waterSourceController = TextEditingController(text: f?.waterSource ?? '');
    _notesController = TextEditingController(text: f?.notes ?? '');

    if (f != null) {
      if (_soilTypes.contains(f.soilType)) _selectedSoilType = f.soilType;
      if (_irrigationTypes.contains(f.irrigationType)) {
        _selectedIrrigationType = f.irrigationType;
      }
      if (f.ownershipType != null &&
          _ownershipTypes.contains(f.ownershipType)) {
        _selectedOwnership = f.ownershipType!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _waterSourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final area = double.tryParse(_areaController.text.trim()) ?? 1.0;
    final farm = FarmModel(
      id: widget.existingFarm?.id ?? 0,
      farmerProfileId: widget.existingFarm?.farmerProfileId ?? 0,
      farmName: _nameController.text.trim(),
      totalAreaAcres: area,
      soilType: _selectedSoilType,
      irrigationType: _selectedIrrigationType,
      waterSource: _waterSourceController.text.trim().isEmpty
          ? null
          : _waterSourceController.text.trim(),
      location: _locationController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      ownershipType: _selectedOwnership,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(farm);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingFarm != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEdit
                ? Icons.edit_location_alt_rounded
                : Icons.add_home_work_rounded,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isEdit ? 'Edit Farm Plot' : 'Register New Farm'),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Name *',
                    hintText: 'e.g. Green Valley Farm, Shivar Plot 1',
                    prefixIcon: Icon(Icons.terrain_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Please enter a farm name (at least 2 characters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Total Area (Acres) *',
                    hintText: 'e.g. 5.5',
                    prefixIcon: Icon(Icons.square_foot_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter total acreage';
                    }
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) {
                      return 'Enter a valid number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSoilType,
                  decoration: const InputDecoration(
                    labelText: 'Soil Type *',
                    prefixIcon: Icon(Icons.landscape_rounded),
                  ),
                  items: _soilTypes
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSoilType = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIrrigationType,
                  decoration: const InputDecoration(
                    labelText: 'Irrigation Type *',
                    prefixIcon: Icon(Icons.water_drop_rounded),
                  ),
                  items: _irrigationTypes
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedIrrigationType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _waterSourceController,
                  decoration: const InputDecoration(
                    labelText: 'Water Source (Optional)',
                    hintText: 'e.g. Borewell, Canal, Farm Pond',
                    prefixIcon: Icon(Icons.opacity_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Village / Location *',
                    hintText: 'e.g. Baramati Shivar, Plot 14',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter farm location'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(
                          labelText: 'District *',
                          hintText: 'e.g. Pune',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter district'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State *',
                          hintText: 'e.g. Maharashtra',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter state'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedOwnership,
                  decoration: const InputDecoration(
                    labelText: 'Ownership Type',
                    prefixIcon: Icon(Icons.assignment_ind_rounded),
                  ),
                  items: _ownershipTypes
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedOwnership = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Any special remarks or plot boundaries',
                  ),
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
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Save Changes' : 'Register Farm'),
        ),
      ],
    );
  }
}
