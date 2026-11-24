import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/marketplace/models/rental_booking_model.dart';
import 'package:agrochat_app/features/marketplace/repositories/marketplace_repository.dart';

/// Dialog allowing a Farmer to submit an Equipment Rental booking request.
class BookEquipmentDialog extends StatefulWidget {
  const BookEquipmentDialog({
    super.key,
    required this.equipment,
    required this.repository,
  });

  final EquipmentRentalModel equipment;
  final MarketplaceRepository repository;

  @override
  State<BookEquipmentDialog> createState() => _BookEquipmentDialogState();
}

class _BookEquipmentDialogState extends State<BookEquipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  String _rentalType = 'daily';
  int _durationUnits = 2;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _recalcDuration();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalcDuration() {
    final diff = _endDate.difference(_startDate).inDays;
    _durationUnits = diff > 0 ? diff : 1;
  }

  double get _estimatedTotal {
    if (_rentalType == 'hourly') {
      final rate =
          widget.equipment.hourlyRateInr ?? (widget.equipment.dailyRateInr / 8);
      return rate * _durationUnits;
    } else {
      return widget.equipment.dailyRateInr * _durationUnits;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'equipment_id': widget.equipment.id,
        'start_date': _formatDate(_startDate),
        'end_date': _formatDate(_endDate),
        'rental_type': _rentalType,
        'duration_units': _durationUnits,
        'delivery_location': _locationController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'farmer_notes': _notesController.text.trim(),
      };

      final booking = await widget.repository.bookEquipment(payload);
      if (mounted) {
        Navigator.of(context).pop(booking);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book equipment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
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
                        'Book Machinery Rental',
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
                const SizedBox(height: 10),
                Text(
                  widget.equipment.equipmentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  'Daily Rate: Rs. ${widget.equipment.dailyRateInr.toStringAsFixed(0)} | Provider: ${widget.equipment.providerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  'Start: ${_formatDate(_startDate)}',
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 90),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _startDate = picked;
                                      if (_endDate.isBefore(_startDate)) {
                                        _endDate = _startDate.add(
                                          const Duration(days: 1),
                                        );
                                      }
                                      _recalcDuration();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event_rounded, size: 16),
                                label: Text('End: ${_formatDate(_endDate)}'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _endDate,
                                    firstDate: _startDate,
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 90),
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _endDate = picked;
                                      _recalcDuration();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _rentalType,
                          decoration: const InputDecoration(
                            labelText: 'Rental Duration Type',
                            prefixIcon: Icon(Icons.timer_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text('Daily Rental'),
                            ),
                            DropdownMenuItem(
                              value: 'hourly',
                              child: Text('Hourly Rental'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _rentalType = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery / Farm Location *',
                            hintText: 'e.g., Plot #4, Near Canal, Baramati',
                            prefixIcon: Icon(Icons.place_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 3) {
                              return 'Enter farm delivery location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone Number *',
                            hintText: 'e.g., +91 9876543210',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 10) {
                              return 'Enter valid 10-digit phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Operator / Farm Notes (Optional)',
                            hintText: 'e.g., Need tractor operator for 2 days',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.softMint,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Estimated Cost ($_durationUnits $_rentalType${_durationUnits > 1 ? 's' : ''}):',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${_estimatedTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreenDark,
                                ),
                              ),
                            ],
                          ),
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
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm Booking'),
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
