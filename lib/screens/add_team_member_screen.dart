import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/team.dart';
import '../services/storage_service.dart';

class AddTeamMemberScreen extends StatefulWidget {
  final TeamMember? member;

  const AddTeamMemberScreen({super.key, this.member});

  @override
  State<AddTeamMemberScreen> createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends State<AddTeamMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _salaryController = TextEditingController();
  final _walletController = TextEditingController();
  final _telegramController = TextEditingController();
  final _storageService = StorageService();

  String _salaryType = 'monthly';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _emailController.text = widget.member!.email;
      _phoneController.text = widget.member!.phone ?? '';
      _roleController.text = widget.member!.role;
      _salaryController.text = widget.member!.salary.toString();
      _walletController.text = widget.member!.walletAddress ?? '';
      _telegramController.text = widget.member!.telegramId ?? '';
      _salaryType = widget.member!.salaryType;
      _isActive = widget.member!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _salaryController.dispose();
    _walletController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final member = TeamMember(
        id: widget.member?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _roleController.text.trim(),
        salary: double.parse(_salaryController.text),
        salaryType: _salaryType,
        walletAddress: _walletController.text.trim().isEmpty
            ? null
            : _walletController.text.trim(),
        telegramId: _telegramController.text.trim().isEmpty
            ? null
            : _telegramController.text.trim(),
        isActive: _isActive,
        createdAt: widget.member?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        payments: widget.member?.payments ?? [],
      );

      if (widget.member == null) {
        await _storageService.addTeamMember(member);
      } else {
        await _storageService.updateTeamMember(member);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.white70),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE0E0E0),
                                          Color(0xFFD0D0D0),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.person_add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Member Details',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              _buildCompactDivider(),
                              Expanded(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    _buildCompactTextField(
                                      controller: _nameController,
                                      label: 'NAME',
                                      hint: 'John Doe',
                                      icon: Icons.badge_rounded,
                                      validator: (v) => v?.isEmpty ?? true
                                          ? 'Required'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCompactTextField(
                                      controller: _emailController,
                                      label: 'EMAIL',
                                      hint: 'john@example.com',
                                      icon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v?.isEmpty ?? true)
                                          return 'Required';
                                        if (!v!.contains('@'))
                                          return 'Invalid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCompactTextField(
                                      controller: _roleController,
                                      label: 'ROLE',
                                      hint: 'Developer, Designer, etc.',
                                      icon: Icons.work_rounded,
                                      validator: (v) => v?.isEmpty ?? true
                                          ? 'Required'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildCompactTextField(
                                            controller: _salaryController,
                                            label: 'SALARY',
                                            hint: '5000',
                                            icon: Icons.attach_money_rounded,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            validator: (v) {
                                              if (v?.isEmpty ?? true)
                                                return 'Required';
                                              if (double.tryParse(v!) == null)
                                                return 'Invalid';
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildSalaryTypeDropdown(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCompactTextField(
                                      controller: _phoneController,
                                      label: 'PHONE',
                                      hint: '+1234567890',
                                      icon: Icons.phone_rounded,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCompactTextField(
                                      controller: _walletController,
                                      label: 'WALLET',
                                      hint: '0x...',
                                      icon:
                                          Icons.account_balance_wallet_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCompactTextField(
                                      controller: _telegramController,
                                      label: 'TELEGRAM',
                                      hint: '@username',
                                      icon: Icons.telegram,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActiveSwitch(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCompactButton(
                        label: _isLoading ? 'Saving...' : 'Save Member',
                        icon: Icons.check_rounded,
                        onPressed: _isLoading ? null : _saveMember,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.member == null
                      ? 'Add Team Member'
                      : 'Edit Team Member',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCompactDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFD0D0D0),
                fontSize: 11,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _salaryType,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'project', child: Text('Project')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _salaryType = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: _isActive
              ? const Color(0xFFAFAFAF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isActive
                    ? [
                        const Color(0xFFAFAFAF),
                        const Color(0xFFAFAFAF).withOpacity(0.7),
                      ]
                    : [Colors.grey, Colors.grey.shade700],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Active Member',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: const Color(0xFFAFAFAF),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFD6D6D6), Color(0xFFAFAFAF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD6D6D6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
