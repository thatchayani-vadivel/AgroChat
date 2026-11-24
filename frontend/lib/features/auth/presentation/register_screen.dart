import 'package:flutter/material.dart';

import 'package:agrochat_app/core/constants/user_role.dart';
import 'package:agrochat_app/core/network/api_exception.dart';
import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/auth/repositories/auth_repository.dart';
import 'package:agrochat_app/features/farmer/presentation/farmer_home_screen.dart';
import 'package:agrochat_app/features/officer/presentation/officer_home_screen.dart';
import 'package:agrochat_app/shared/widgets/agro_logo.dart';
import 'package:agrochat_app/shared/widgets/responsive_container.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Registration screen for Farmers and Agricultural Officers.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.initialRole = UserRole.farmer,
    this.authRepository,
  });

  final UserRole initialRole;
  final AuthRepository? authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Suresh Patil');
  final _emailController = TextEditingController(text: 'suresh@agrochat.com');
  final _phoneController = TextEditingController(text: '+91 9876501234');
  final _passwordController = TextEditingController(text: 'Farmer@123');
  final _confirmPasswordController = TextEditingController(text: 'Farmer@123');

  late UserRole _selectedRole;
  late final AuthRepository _authRepo;

  String _preferredLanguage = 'English';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  static const List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Telugu',
    'Tamil',
    'Kannada',
    'Bengali',
    'Gujarati',
    'Punjabi',
    'Malayalam',
    'Odia',
  ];

  @override
  void initState() {
    super.initState();
    final roleQuery = Uri.base.queryParameters['role']?.toLowerCase();
    if (roleQuery == 'officer' || widget.initialRole == UserRole.agriculturalOfficer) {
      _selectedRole = UserRole.agriculturalOfficer;
      _nameController.text = 'Dr. Rajesh Deshmukh';
      _emailController.text = 'rajesh.officer@agrochat.com';
      _passwordController.text = 'Officer@123';
      _confirmPasswordController.text = 'Officer@123';
    } else {
      _selectedRole = UserRole.farmer;
    }
    _authRepo = widget.authRepository ?? AuthRepository();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _authRepo.register(
        role: _selectedRole,
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        preferredLanguage: _preferredLanguage,
      );

      if (!mounted) return;
      showSuccessSnackBar(context, 'Account created successfully!');
      _navigateToHome(session);
    } on ApiException catch (exc) {
      if (!mounted) return;
      setState(() {
        _errorMessage = exc.message;
      });
      showErrorSnackBar(context, exc.message);
    } catch (_) {
      if (!mounted) return;
      const genericMsg =
          'Registration failed. Please check your network and try again.';
      setState(() {
        _errorMessage = genericMsg;
      });
      showErrorSnackBar(context, genericMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome(AuthSession session) {
    final Widget destination = session.user.role == UserRole.farmer
        ? FarmerHomeScreen(session: session, authRepository: _authRepo)
        : OfficerHomeScreen(session: session, authRepository: _authRepo);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AgroLogo(size: 64, showTitle: false),
                  const SizedBox(height: 8),
                  Text(
                    'Join AgroChat Platform',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your role to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildRoleSelector(context),
                  const SizedBox(height: 20),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _selectedRole == UserRole.farmer
                          ? 'Farmer Full Name'
                          : 'Officer Full Name',
                      hintText: 'e.g. Ramesh Kumar',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Please enter at least 2 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'e.g. user@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email.';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. +91 9876543210',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number.';
                      }
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 7 || digits.length > 15) {
                        return 'Phone number must contain 7-15 digits.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _preferredLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Language',
                      prefixIcon: Icon(Icons.language_rounded),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _preferredLanguage = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password (min. 8 characters)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Password must be at least 8 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Register as ${_selectedRole.displayName}'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softMint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _roleOption(
              role: UserRole.farmer,
              icon: Icons.agriculture_rounded,
            ),
          ),
          Expanded(
            child: _roleOption(
              role: UserRole.agriculturalOfficer,
              icon: Icons.support_agent_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleOption({required UserRole role, required IconData icon}) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                role.displayName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
