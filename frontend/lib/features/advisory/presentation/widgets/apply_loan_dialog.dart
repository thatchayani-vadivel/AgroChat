import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/advisory/models/advisory_model.dart';
import 'package:agrochat_app/features/advisory/repositories/advisory_repository.dart';

/// Dialog allowing a Farmer to submit an Agricultural Loan Enquiry for Officer guidance.
class ApplyLoanDialog extends StatefulWidget {
  const ApplyLoanDialog({super.key, required this.repository, this.scheme});

  final AdvisoryRepository repository;
  final SchemeModel? scheme;

  @override
  State<ApplyLoanDialog> createState() => _ApplyLoanDialogState();
}

class _ApplyLoanDialogState extends State<ApplyLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _incomeController = TextEditingController();
  final _landController = TextEditingController();
  final _bankController = TextEditingController();

  String _loanType = 'Kisan Credit Card (Crop Loan)';
  bool _isSubmitting = false;

  final List<String> _loanTypes = [
    'Kisan Credit Card (Crop Loan)',
    'Agricultural Infrastructure Loan',
    'Tractor & Farm Machinery Loan',
    'Dairy & Livestock Term Loan',
    'Solar Pump Installation Loan',
    'Micro-Irrigation Term Loan',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.scheme != null) {
      _loanType = widget.scheme!.title;
      _purposeController.text =
          'Seeking advisory and guidance for ${widget.scheme!.title}.';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _incomeController.dispose();
    _landController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final income = _incomeController.text.trim().isNotEmpty
          ? double.tryParse(_incomeController.text.trim())
          : null;
      final land = _landController.text.trim().isNotEmpty
          ? double.tryParse(_landController.text.trim())
          : null;

      final payload = <String, dynamic>{
        'loan_type': _loanType,
        if (widget.scheme != null) 'scheme_id': widget.scheme!.id,
        'requested_amount_inr': amount,
        'purpose': _purposeController.text.trim(),
        if (_bankController.text.trim().isNotEmpty)
          'preferred_bank': _bankController.text.trim(),
      };
      if (income != null) payload['annual_income_inr'] = income;
      if (land != null) payload['land_holding_acres'] = land;

      final enquiry = await widget.repository.submitLoanEnquiry(payload);
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                        'Agricultural Loan Enquiry',
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
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _loanTypes.contains(_loanType)
                              ? _loanType
                              : _loanTypes.first,
                          decoration: const InputDecoration(
                            labelText: 'Loan Type *',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_rounded,
                            ),
                          ),
                          items: _loanTypes.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _loanType = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Requested Loan Amount (INR) *',
                            hintText: 'e.g. 150000',
                            prefixIcon: Icon(Icons.currency_rupee_rounded),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter loan amount';
                            }
                            final n = double.tryParse(v.trim());
                            if (n == null || n <= 0) {
                              return 'Enter a valid positive number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _purposeController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Purpose of Loan *',
                            hintText: 'Describe inputs to purchase, equipment, or farm activity...',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().length < 5) {
                              return 'Enter at least 5 characters for purpose';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bankController,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Bank (Optional)',
                            hintText:
                                'e.g., State Bank of India, District Co-op',
                            prefixIcon: Icon(Icons.account_balance_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _incomeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Annual Income (INR)',
                                  hintText: 'e.g. 180000',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _landController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Land Area (Acres)',
                                  hintText: 'e.g. 4.5',
                                ),
                              ),
                            ),
                          ],
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
