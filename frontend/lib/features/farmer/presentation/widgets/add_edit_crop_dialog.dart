import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';

/// Form dialog to cultivate a new crop on a farm or update crop details.
class AddEditCropDialog extends StatefulWidget {
  const AddEditCropDialog({super.key, required this.farmId, this.existingCrop});

  final int farmId;
  final CropModel? existingCrop;

  @override
  State<AddEditCropDialog> createState() => _AddEditCropDialogState();
}

class _AddEditCropDialogState extends State<AddEditCropDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _varietyController;
  late TextEditingController _areaController;
  late TextEditingController _yieldController;
  late TextEditingController _notesController;

  String _selectedSeason = 'Kharif';
  String _selectedGrowthStage = 'Vegetative';
  String? _sowingDate;
  String? _expectedHarvestDate;

  final List<String> _seasons = [
    'Kharif',
    'Rabi',
    'Zaid (Summer)',
    'Year-round',
    'Perennial',
  ];

  final List<String> _growthStages = [
    'Sowing / Germination',
    'Vegetative',
    'Flowering',
    'Fruit / Pod Formation',
    'Maturity',
    'Harvesting',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.existingCrop;
    _nameController = TextEditingController(text: c?.cropName ?? '');
    _varietyController = TextEditingController(text: c?.variety ?? '');
    _areaController = TextEditingController(
      text: c != null ? c.areaAcres.toString() : '',
    );
    _yieldController = TextEditingController(
      text: c?.estimatedYieldKg != null ? c!.estimatedYieldKg.toString() : '',
    );
    _notesController = TextEditingController(text: c?.notes ?? '');

    if (c != null) {
      if (_seasons.contains(c.season)) _selectedSeason = c.season;
      if (c.growthStage != null && _growthStages.contains(c.growthStage)) {
        _selectedGrowthStage = c.growthStage!;
      }
      _sowingDate = c.sowingDate;
      _expectedHarvestDate = c.expectedHarvestDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varietyController.dispose();
    _areaController.dispose();
    _yieldController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isSowing}) async {
    final now = DateTime.now();
    final initial = isSowing ? now : now.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isSowing) {
          _sowingDate = formatted;
        } else {
          _expectedHarvestDate = formatted;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final area = double.tryParse(_areaController.text.trim()) ?? 1.0;
    final estYield = double.tryParse(_yieldController.text.trim());

    final crop = CropModel(
      id: widget.existingCrop?.id ?? 0,
      farmId: widget.farmId,
      cropName: _nameController.text.trim(),
      variety: _varietyController.text.trim().isEmpty
          ? null
          : _varietyController.text.trim(),
      season: _selectedSeason,
      areaAcres: area,
      sowingDate: _sowingDate,
      expectedHarvestDate: _expectedHarvestDate,
      growthStage: _selectedGrowthStage,
      estimatedYieldKg: estYield,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(crop);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingCrop != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit_note_rounded : Icons.grass_rounded,
            color: AppColors.primaryGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(isEdit ? 'Edit Crop Details' : 'Add Crop to Farm'),
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
                    labelText: 'Crop Name *',
                    hintText: 'e.g. Sugarcane, Wheat, Cotton, Tomato',
                    prefixIcon: Icon(Icons.eco_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Enter crop name (at least 2 letters)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _varietyController,
                  decoration: const InputDecoration(
                    labelText: 'Variety / Hybrid (Optional)',
                    hintText: 'e.g. Co 86032, HD-2967, Desi Gold',
                    prefixIcon: Icon(Icons.grain_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedSeason,
                        decoration: const InputDecoration(
                          labelText: 'Season *',
                        ),
                        items: _seasons
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSeason = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Area (Acres) *',
                          hintText: 'e.g. 3.0',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter area';
                          }
                          final n = double.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedGrowthStage,
                  decoration: const InputDecoration(
                    labelText: 'Current Growth Stage',
                    prefixIcon: Icon(Icons.trending_up_rounded),
                  ),
                  items: _growthStages
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGrowthStage = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isSowing: true),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _sowingDate == null
                              ? 'Sowing Date'
                              : 'Sown: $_sowingDate',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isSowing: false),
                        icon: const Icon(
                          Icons.event_available_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _expectedHarvestDate == null
                              ? 'Harvest Date'
                              : 'Harvest: $_expectedHarvestDate',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _yieldController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Estimated Yield (Kg) (Optional)',
                    hintText: 'e.g. 5000',
                    prefixIcon: Icon(Icons.scale_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Spray Schedule',
                    hintText: 'e.g. First fertilizer application completed',
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
          child: Text(isEdit ? 'Update Crop' : 'Save Crop'),
        ),
      ],
    );
  }
}
