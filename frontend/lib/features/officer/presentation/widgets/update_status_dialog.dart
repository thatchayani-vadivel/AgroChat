import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';

class RequestStatusUpdateResult {
  const RequestStatusUpdateResult({
    required this.status,
    this.officerNotes,
    this.guidanceSummary,
    this.recommendations,
  });

  final String status;
  final String? officerNotes;
  final String? guidanceSummary;
  final String? recommendations;
}

/// Modal dialog for an Agricultural Officer to update request status (in_progress / resolved)
/// and record official guidance and recommendations.
class UpdateStatusDialog extends StatefulWidget {
  const UpdateStatusDialog({
    super.key,
    required this.currentStatus,
    this.existingNotes,
  });

  final String currentStatus;
  final String? existingNotes;

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedStatus;
  late TextEditingController _notesController;
  late TextEditingController _guidanceController;
  late TextEditingController _recommendationsController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus.toLowerCase() == 'resolved'
        ? 'resolved'
        : 'in_progress';
    _notesController = TextEditingController(text: widget.existingNotes ?? '');
    _guidanceController = TextEditingController();
    _recommendationsController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _guidanceController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final result = RequestStatusUpdateResult(
        status: _selectedStatus,
        officerNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        guidanceSummary: _guidanceController.text.trim().isNotEmpty
            ? _guidanceController.text.trim()
            : null,
        recommendations: _recommendationsController.text.trim().isNotEmpty
            ? _recommendationsController.text.trim()
            : null,
      );
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.published_with_changes_rounded,
            color: AppColors.primaryGreen,
          ),
          SizedBox(width: 8),
          Expanded(child: Text('Update Advisory Status')),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Target Status *',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text(
                        'In Progress (Active Guidance / Investigation)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved (Completed Advisory)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Officer Internal Notes (Optional)',
                    hintText:
                        'Plot observations, test results, or next steps...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _guidanceController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Farmer Guidance Summary (Optional)',
                    hintText: 'Diagnosis of pest, nutrient deficiency, or irrigation guidance...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recommendationsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Recommended Action / Treatments (Optional)',
                    hintText: 'Specific fertilizer dosage, spray schedule, bio-pesticides...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Update Status')),
      ],
    );
  }
}
