import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';

/// Modal dialog for an Agricultural Officer to edit their professional profile, specialization, and jurisdiction.
class EditOfficerProfileDialog extends StatefulWidget {
  const EditOfficerProfileDialog({super.key, required this.existingProfile});

  final OfficerProfileModel existingProfile;

  @override
  State<EditOfficerProfileDialog> createState() =>
      _EditOfficerProfileDialogState();
}

class _EditOfficerProfileDialogState extends State<EditOfficerProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _designationCtrl;
  late TextEditingController _departmentCtrl;
  late TextEditingController _specializationCtrl;
  late TextEditingController _qualificationsCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _languagesCtrl;
  late TextEditingController _officeLocationCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _hoursCtrl;
  late TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _designationCtrl = TextEditingController(text: p.designation);
    _departmentCtrl = TextEditingController(text: p.department ?? '');
    _specializationCtrl = TextEditingController(text: p.specialization);
    _qualificationsCtrl = TextEditingController(text: p.qualifications ?? '');
    _experienceCtrl = TextEditingController(text: '${p.experienceYears}');
    _languagesCtrl = TextEditingController(text: p.languagesSpoken);
    _officeLocationCtrl = TextEditingController(text: p.officeLocation ?? '');
    _districtCtrl = TextEditingController(text: p.district);
    _stateCtrl = TextEditingController(text: p.state);
    _hoursCtrl = TextEditingController(text: p.availabilityHours ?? '');
    _bioCtrl = TextEditingController(text: p.bio ?? '');
  }

  @override
  void dispose() {
    _designationCtrl.dispose();
    _departmentCtrl.dispose();
    _specializationCtrl.dispose();
    _qualificationsCtrl.dispose();
    _experienceCtrl.dispose();
    _languagesCtrl.dispose();
    _officeLocationCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _hoursCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final updated = widget.existingProfile.copyWith(
        designation: _designationCtrl.text.trim(),
        department: _departmentCtrl.text.trim().isNotEmpty
            ? _departmentCtrl.text.trim()
            : null,
        specialization: _specializationCtrl.text.trim(),
        qualifications: _qualificationsCtrl.text.trim().isNotEmpty
            ? _qualificationsCtrl.text.trim()
            : null,
        experienceYears: int.tryParse(_experienceCtrl.text.trim()) ?? 0,
        languagesSpoken: _languagesCtrl.text.trim(),
        officeLocation: _officeLocationCtrl.text.trim().isNotEmpty
            ? _officeLocationCtrl.text.trim()
            : null,
        district: _districtCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        availabilityHours: _hoursCtrl.text.trim().isNotEmpty
            ? _hoursCtrl.text.trim()
            : null,
        bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : null,
      );
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.badge_rounded, color: AppColors.primaryGreen),
          SizedBox(width: 8),
          Expanded(child: Text('Edit Officer Profile')),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _designationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Designation *',
                    hintText:
                        'e.g. Agricultural Officer, Taluka Krishi Adhikari',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Designation is required'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _departmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department / Ministry',
                    hintText:
                        'e.g. Department of Agriculture & Farmers Welfare',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _specializationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Specialization *',
                    hintText: 'e.g. Plant Pathology, Soil Science, Agronomy',
                    prefixIcon: Icon(Icons.psychology_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Specialization is required'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qualificationsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Qualifications',
                          hintText: 'e.g. M.Sc. Agriculture',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _experienceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Experience (Years)',
                          prefixIcon: Icon(Icons.timeline_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _languagesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Languages Spoken *',
                    hintText: 'e.g. English, Hindi, Marathi',
                    prefixIcon: Icon(Icons.language_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Languages are required'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _officeLocationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Office Address / Taluka Kendra',
                    hintText:
                        'e.g. Krishi Bhavan, Room 104, Sub-Divisional Office',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jurisdiction District *',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'District is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _stateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jurisdiction State *',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'State is required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _hoursCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Hours',
                    hintText: 'e.g. Mon-Fri 09:30 AM - 05:30 PM',
                    prefixIcon: Icon(Icons.access_time_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Professional Bio / Summary',
                    hintText: 'Brief summary of background, research, or farmer guidance experience',
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
        ElevatedButton(onPressed: _submit, child: const Text('Save Profile')),
      ],
    );
  }
}
