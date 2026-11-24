import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';

/// Dialog allowing a Farmer to submit a new Agricultural Assistance Request.
class CreateRequestDialog extends StatefulWidget {
  const CreateRequestDialog({
    super.key,
    required this.repository,
    required this.farms,
  });

  final FarmerRepository repository;
  final List<FarmModel> farms;

  @override
  State<CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<CreateRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'crop_advisory';
  String _priority = 'medium';
  FarmModel? _selectedFarm;
  CropModel? _selectedCrop;
  OfficerProfileModel? _preferredOfficer;

  bool _isSubmitting = false;
  List<OfficerProfileModel> _availableOfficers = [];

  final List<Map<String, String>> _categories = [
    {'value': 'crop_advisory', 'label': 'General Crop Advisory'},
    {'value': 'pest_control', 'label': 'Pest & Insect Attack'},
    {'value': 'disease_diagnosis', 'label': 'Plant Disease Diagnosis'},
    {'value': 'soil_health', 'label': 'Soil Health & Fertilizer'},
    {'value': 'irrigation_guidance', 'label': 'Water & Irrigation'},
    {'value': 'weather_impact', 'label': 'Weather & Climate Damage'},
    {'value': 'other', 'label': 'Other Agricultural Problem'},
  ];

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    if (widget.farms.isNotEmpty) {
      _selectedFarm = widget.farms.first;
      if (_selectedFarm!.crops.isNotEmpty) {
        _selectedCrop = _selectedFarm!.crops.first;
      }
    }
    _loadOfficers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficers() async {
    try {
      final officers = await widget.repository.listAvailableOfficers();
      if (mounted) {
        setState(() {
          _availableOfficers = officers;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'category': _category,
        'description': _descriptionController.text.trim(),
        'priority': _priority,
        if (_selectedFarm != null) 'farm_id': _selectedFarm!.id,
        if (_selectedCrop != null) 'crop_id': _selectedCrop!.id,
        if (_preferredOfficer != null)
          'preferred_officer_id': _preferredOfficer!.userId,
      };

      final created = await widget.repository.createRequest(payload);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropsForFarm = _selectedFarm?.crops ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Request Officer Guidance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Problem Summary *',
                            hintText: 'e.g., Yellowing leaves in wheat crop',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 5) {
                              return 'Enter at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c['value'],
                              child: Text(c['label']!, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _category = val);
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _priority,
                          decoration: const InputDecoration(
                            labelText: 'Priority Level *',
                            prefixIcon: Icon(Icons.priority_high_rounded),
                          ),
                          items: _priorities.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                        const SizedBox(height: 14),
                        if (widget.farms.isNotEmpty) ...[
                          DropdownButtonFormField<FarmModel>(
                            isExpanded: true,
                            initialValue: _selectedFarm,
                            decoration: const InputDecoration(
                              labelText: 'Affected Farm (Optional)',
                              prefixIcon: Icon(Icons.landscape_rounded),
                            ),
                            items: widget.farms.map((farm) {
                              return DropdownMenuItem(
                                value: farm,
                                child: Text(
                                  '${farm.farmName} (${farm.district})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (farm) {
                              setState(() {
                                _selectedFarm = farm;
                                _selectedCrop =
                                    (farm != null && farm.crops.isNotEmpty)
                                    ? farm.crops.first
                                    : null;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          if (cropsForFarm.isNotEmpty) ...[
                            DropdownButtonFormField<CropModel>(
                              isExpanded: true,
                              initialValue: _selectedCrop,
                              decoration: const InputDecoration(
                                labelText: 'Cultivated Crop (Optional)',
                                prefixIcon: Icon(Icons.grass_rounded),
                              ),
                              items: cropsForFarm.map((crop) {
                                return DropdownMenuItem(
                                  value: crop,
                                  child: Text(
                                    '${crop.cropName} (${crop.season})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (crop) =>
                                  setState(() => _selectedCrop = crop),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                        if (_availableOfficers.isNotEmpty) ...[
                          DropdownButtonFormField<OfficerProfileModel>(
                            isExpanded: true,
                            initialValue: _preferredOfficer,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Officer (Optional)',
                              prefixIcon: Icon(Icons.badge_rounded),
                            ),
                            items: [
                              const DropdownMenuItem<OfficerProfileModel>(
                                value: null,
                                child: Text(
                                  'Any Available Agricultural Officer',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ..._availableOfficers.map((o) {
                                return DropdownMenuItem(
                                  value: o,
                                  child: Text(
                                    '${o.fullName} (${o.district})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (o) =>
                                setState(() => _preferredOfficer = o),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Detailed Description *',
                            hintText: 'Describe symptoms, farm conditions, fertilizer used, pest sightings...',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 10) {
                              return 'Enter at least 10 characters describing the issue';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.surfaceWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surfaceWhite,
                              ),
                            )
                          : const Text('Submit Request'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
