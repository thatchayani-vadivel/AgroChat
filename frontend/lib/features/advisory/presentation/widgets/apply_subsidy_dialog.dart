import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/advisory/models/advisory_model.dart';
import 'package:agrochat_app/features/advisory/repositories/advisory_repository.dart';

/// Dialog allowing a Farmer to submit a Subsidy Assistance Enquiry for Officer guidance.
class ApplySubsidyDialog extends StatefulWidget {
  const ApplySubsidyDialog({super.key, required this.repository, this.scheme});

  final AdvisoryRepository repository;
  final SchemeModel? scheme;

  @override
  State<ApplySubsidyDialog> createState() => _ApplySubsidyDialogState();
}

class _ApplySubsidyDialogState extends State<ApplySubsidyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.scheme != null) {
      _titleController.text = widget.scheme!.title;
      _detailsController.text =
          'Requesting agricultural officer guidance and document verification for ${widget.scheme!.title}.';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = <String, dynamic>{
        'subsidy_title': _titleController.text.trim(),
        if (widget.scheme != null) 'scheme_id': widget.scheme!.id,
        'enquiry_details': _detailsController.text.trim(),
      };

      final enquiry = await widget.repository.submitSubsidyEnquiry(payload);
      if (mounted) {
        Navigator.of(context).pop(enquiry);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit enquiry: $e'),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
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
                        'Subsidy Scheme Enquiry',
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
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Subsidy / Scheme Name *',
                            hintText:
                                'e.g., Per Drop More Crop (Drip Irrigation)',
                            prefixIcon: Icon(Icons.spa_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Enter subsidy name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _detailsController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Enquiry Details & Farm Requirement *',
                            hintText: 'Describe equipment type, farm plot details, quotation status...',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 5) {
                              return 'Enter at least 5 characters';
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
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                          : const Text('Submit Enquiry'),
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
