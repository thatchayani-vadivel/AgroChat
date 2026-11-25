import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/advisory/models/advisory_model.dart';
import 'package:agrochat_app/features/advisory/models/loan_model.dart';
import 'package:agrochat_app/features/advisory/models/subsidy_model.dart';
import 'package:agrochat_app/features/advisory/presentation/widgets/apply_loan_dialog.dart';
import 'package:agrochat_app/features/advisory/presentation/widgets/apply_subsidy_dialog.dart';
import 'package:agrochat_app/features/advisory/repositories/advisory_repository.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing Farmers to browse Government Schemes, Subsidies, Loans & Insurance,
/// submit enquiries for Officer guidance, and discover local agricultural centers.
class FarmerAdvisoryScreen extends StatefulWidget {
  const FarmerAdvisoryScreen({super.key, required this.repository});

  final AdvisoryRepository repository;

  @override
  State<FarmerAdvisoryScreen> createState() => _FarmerAdvisoryScreenState();
}

class _FarmerAdvisoryScreenState extends State<FarmerAdvisoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<SchemeModel> _schemes = [];
  List<LoanEnquiryModel> _loanEnquiries = [];
  List<SubsidyEnquiryModel> _subsidyEnquiries = [];
  List<AgriculturalServiceModel> _services = [];

  String _schemeCategoryFilter = 'all';
  String _searchQuery = '';

  final List<String> _schemeCategories = [
    'all',
    'scheme',
    'subsidy',
    'loan',
    'insurance',
  ];

  @override
  void initState() {
    super.initState();
    final tabParam = Uri.base.queryParameters['tab']?.toLowerCase();
    int initialTab = 0;
    if (tabParam == 'enquiries') {
      initialTab = 1;
    } else if (tabParam == 'centers' || tabParam == 'services') {
      initialTab = 2;
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTab);
    final catParam = Uri.base.queryParameters['cat']?.toLowerCase();
    if (catParam != null && _schemeCategories.contains(catParam)) {
      _schemeCategoryFilter = catParam;
    }
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schemesFuture = widget.repository.listSchemes();
      final loansFuture = widget.repository.listMyLoanEnquiries();
      final subsidiesFuture = widget.repository.listMySubsidyEnquiries();
      final servicesFuture = widget.repository.listServices();

      final results = await Future.wait([
        schemesFuture,
        loansFuture,
        subsidiesFuture,
        servicesFuture,
      ]);

      if (mounted) {
        setState(() {
          _schemes = results[0] as List<SchemeModel>;
          _loanEnquiries = results[1] as List<LoanEnquiryModel>;
          _subsidyEnquiries = results[2] as List<SubsidyEnquiryModel>;
          _services = results[3] as List<AgriculturalServiceModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<SchemeModel> get _filteredSchemes {
    return _schemes.where((s) {
      final matchCat =
          _schemeCategoryFilter == 'all' ||
          s.category.toLowerCase() == _schemeCategoryFilter.toLowerCase();
      final matchSearch =
          _searchQuery.isEmpty ||
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.provider.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _showSchemeDetails(SchemeModel scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softMint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Text(
                          scheme.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreenDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        scheme.state,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    scheme.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Provided by: ${scheme.provider}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _buildSection('Overview', scheme.description),
                  _buildSection('Key Benefits', scheme.benefits),
                  _buildSection('Eligibility Criteria', scheme.eligibility),
                  if (scheme.requiredDocuments != null)
                    _buildSection(
                      'Required Documents',
                      scheme.requiredDocuments!,
                    ),
                  if (scheme.applicationProcess != null)
                    _buildSection(
                      'Application Process',
                      scheme.applicationProcess!,
                    ),
                  if (scheme.officialLink != null)
                    _buildSection('Official Portal', scheme.officialLink!),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (scheme.category == 'loan') {
                        _openApplyLoan(scheme: scheme);
                      } else {
                        _openApplySubsidy(scheme: scheme);
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Enquire with Agricultural Officer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreenDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openApplyLoan({SchemeModel? scheme}) async {
    final result = await showDialog<LoanEnquiryModel>(
      context: context,
      builder: (_) =>
          ApplyLoanDialog(repository: widget.repository, scheme: scheme),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan enquiry submitted successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      _loadAllData();
      _tabController.animateTo(1);
    }
  }

  Future<void> _openApplySubsidy({SchemeModel? scheme}) async {
    final result = await showDialog<SubsidyEnquiryModel>(
      context: context,
      builder: (_) =>
          ApplySubsidyDialog(repository: widget.repository, scheme: scheme),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subsidy enquiry submitted successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      _loadAllData();
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Schemes & Subsidies'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.surfaceWhite,
                unselectedLabelColor: AppColors.surfaceWhite.withValues(alpha: 0.7),
                indicatorColor: AppColors.softMint,
                tabs: const [
                  Tab(text: 'Schemes & Subsidies'),
                  Tab(text: 'My Enquiries'),
                  Tab(text: 'Agri Centers'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const AgroLoadingView(message: 'Loading government schemes...')
          : _errorMessage != null && _schemes.isEmpty
          ? AgroEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to Load Schemes',
              description: _errorMessage!,
              actionLabel: 'Retry',
              onAction: _loadAllData,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSchemesTab(),
                    _buildEnquiriesTab(),
                    _buildServicesTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSchemesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceWhite,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search schemes, subsidies, loans...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _schemeCategories.map((c) {
                    final isSelected = _schemeCategoryFilter == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(c.toUpperCase()),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                        backgroundColor: AppColors.background,
                        selectedColor: AppColors.primaryGreen,
                        onSelected: (_) =>
                            setState(() => _schemeCategoryFilter = c),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _filteredSchemes.isEmpty
              ? const AgroEmptyState(
                  icon: Icons.policy_rounded,
                  title: 'No Schemes Match',
                  description: 'Try switching filter categories or clearing search keywords.',
                )
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSchemes.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final scheme = _filteredSchemes[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showSchemeDetails(scheme),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.softMint,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        scheme.category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreenDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      scheme.state,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  scheme.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  scheme.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        scheme.benefits,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEnquiriesTab() {
    final totalEnquiries = _loanEnquiries.length + _subsidyEnquiries.length;

    return Scaffold(
      body: totalEnquiries == 0
          ? AgroEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No Active Enquiries',
              description: 'Need assistance with crop loans or micro-irrigation subsidies? Submit an enquiry to connect with your agricultural officer.',
              actionLabel: 'Submit Loan Enquiry',
              onAction: () => _openApplyLoan(),
            )
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loanEnquiries.isNotEmpty) ...[
                    const Text(
                      'Agricultural Loan Enquiries',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._loanEnquiries.map(_buildLoanCard),
                    const SizedBox(height: 16),
                  ],
                  if (_subsidyEnquiries.isNotEmpty) ...[
                    const Text(
                      'Subsidy Scheme Enquiries',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._subsidyEnquiries.map(_buildSubsidyCard),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.surfaceWhite,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Enquiry'),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select Enquiry Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.softMint,
                      child: Icon(
                        Icons.currency_rupee_rounded,
                        color: AppColors.primaryGreenDark,
                      ),
                    ),
                    title: const Text('Agricultural Loan Advisory'),
                    subtitle: const Text(
                      'KCC crop loan, term loans, solar pump financing',
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openApplyLoan();
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.spa_rounded, color: Colors.deepOrange),
                    ),
                    title: const Text('Subsidy Scheme Guidance'),
                    subtitle: const Text(
                      'Micro-irrigation, solar pumps, farm mechanization',
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openApplySubsidy();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanCard(LoanEnquiryModel loan) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    loan.loanType,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    loan.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Amount: Rs. ${loan.requestedAmountInr.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              'Purpose: ${loan.purpose}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (loan.officerGuidance != null &&
                loan.officerGuidance!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softMint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Officer Guidance: ${loan.officerGuidance}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubsidyCard(SubsidyEnquiryModel sub) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sub.subsidyTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    sub.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sub.enquiryDetails,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (sub.officerGuidance != null &&
                sub.officerGuidance!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softMint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Officer Guidance: ${sub.officerGuidance}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return _services.isEmpty
        ? const AgroEmptyState(
            icon: Icons.location_on_outlined,
            title: 'No Agri Centers Available',
            description: 'Local Krishi Vigyan Kendras and laboratories will appear here.',
          )
        : RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _services.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = _services[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.softMint,
                              child: Icon(
                                Icons.place_rounded,
                                color: AppColors.primaryGreenDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    s.serviceType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Address: ${s.address}, ${s.district}, ${s.state}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (s.contactPhone.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Phone: ${s.contactPhone}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreenDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (s.workingHours != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Hours: ${s.workingHours}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }
}
