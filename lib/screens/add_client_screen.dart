import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../services/storage_service.dart';

class AddClientScreen extends StatefulWidget {
  final Client? client; // For editing existing client

  const AddClientScreen({super.key, this.client});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _walletController = TextEditingController();
  final _storageService = StorageService();

  List<ClientMilestone> _milestones = [];
  bool _isLoading = false;
  int _currentStep = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.client != null) {
      _nameController.text = widget.client!.name;
      _emailController.text = widget.client!.email;
      _phoneController.text = widget.client!.phone ?? '';
      _telegramController.text = widget.client!.telegramId ?? '';
      _walletController.text = widget.client!.walletAddress ?? '';
      _milestones = List.from(widget.client!.milestones);
    }
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  void _addMilestone() {
    showDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        onSave: (milestone) {
          setState(() => _milestones.add(milestone));
        },
      ),
    );
  }

  void _editMilestone(int index) {
    showDialog(
      context: context,
      builder: (context) => _MilestoneDialog(
        milestone: _milestones[index],
        onSave: (milestone) {
          setState(() => _milestones[index] = milestone);
        },
      ),
    );
  }

  void _deleteMilestone(int index) {
    setState(() => _milestones.removeAt(index));
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = Client(
        id: widget.client?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        telegramId: _telegramController.text.trim().isEmpty
            ? null
            : _telegramController.text.trim(),
        walletAddress: _walletController.text.trim().isEmpty
            ? null
            : _walletController.text.trim(),
        milestones: _milestones,
        createdAt: widget.client?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.client == null) {
        await _storageService.addClient(client);
      } else {
        await _storageService.updateClient(client);
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
            // Glassmorphic Header
            _buildHeader(),

            // Step Indicators
            _buildStepIndicators(),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _currentStep == 0
                    ? _buildClientDetailsStep()
                    : _buildMilestonesStep(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
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
                  widget.client == null ? 'Add Client' : 'Edit Client',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Details', Icons.person_rounded),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentStep >= 1
                      ? [const Color(0xFFD6D6D6), const Color(0xFFAFAFAF)]
                      : [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                ),
              ),
            ),
          ),
          _buildStepIndicator(1, 'Milestones', Icons.flag_rounded),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFD6D6D6), Color(0xFFAFAFAF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFFD6D6D6)
                  : Colors.white.withOpacity(0.1),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFD6D6D6).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildClientDetailsStep() {
    return Padding(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact single glass card
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
                              colors: [Color(0xFFD6D6D6), Color(0xFFAFAFAF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Client Details',
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
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactTextField(
                            controller: _emailController,
                            label: 'EMAIL',
                            hint: 'john@example.com',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              if (!v!.contains('@')) return 'Invalid email';
                              return null;
                            },
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
                            controller: _telegramController,
                            label: 'TELEGRAM',
                            hint: '@username',
                            icon: Icons.telegram,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactTextField(
                            controller: _walletController,
                            label: 'WALLET',
                            hint: '0x...',
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Next button
            _buildCompactButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() => _currentStep = 1);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesStep() {
    return Padding(
      key: const ValueKey('milestones'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildGlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD0D0D0), Color(0xFFEEEEEE)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Milestones',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _addMilestone,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD6D6D6), Color(0xFFAFAFAF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_milestones.isNotEmpty) _buildCompactDivider(),
                  Expanded(
                    child: _milestones.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No milestones',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: _milestones.length,
                                  itemBuilder: (context, index) {
                                    return _buildCompactMilestoneCard(
                                      _milestones[index],
                                      index,
                                    );
                                  },
                                ),
                              ),
                              if (_milestones.isNotEmpty) ...[
                                _buildCompactDivider(),
                                _buildCompactSummary(),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildCompactButton(
                  label: _isLoading ? 'Saving...' : 'Save',
                  icon: Icons.check_rounded,
                  onPressed: _isLoading ? null : _saveClient,
                ),
              ),
            ],
          ),
        ],
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
          mainAxisSize: MainAxisSize.min,
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

  Widget _buildCompactMilestoneCard(ClientMilestone milestone, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: milestone.isPaid
              ? const Color(0xFFAFAFAF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: milestone.isPaid
                    ? [
                        const Color(0xFFAFAFAF),
                        const Color(0xFFAFAFAF).withOpacity(0.7),
                      ]
                    : [const Color(0xFFEEEEEE), const Color(0xFFD0D0D0)],
              ),
            ),
            child: Icon(
              milestone.isPaid
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${milestone.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editMilestone(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.edit_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _deleteMilestone(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFD0D0D0),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummary() {
    final total = _milestones.fold<double>(0, (sum, m) => sum + m.amount);
    final paid = _milestones
        .where((m) => m.isPaid)
        .fold<double>(0, (sum, m) => sum + m.amount);
    final remaining = total - paid;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', total, const Color(0xFFD6D6D6)),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
          _buildSummaryItem('Paid', paid, const Color(0xFFAFAFAF)),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
          _buildSummaryItem('Due', remaining, const Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(ClientMilestone milestone, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: milestone.isPaid
              ? const Color(0xFFAFAFAF).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: milestone.isPaid
                    ? [
                        const Color(0xFFAFAFAF),
                        const Color(0xFFAFAFAF).withOpacity(0.7),
                      ]
                    : [const Color(0xFFEEEEEE), const Color(0xFFD0D0D0)],
              ),
            ),
            child: Icon(
              milestone.isPaid
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${milestone.amount.toStringAsFixed(2)} USDT',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                if (milestone.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    milestone.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editMilestone(index),
            icon: Icon(
              Icons.edit_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => _deleteMilestone(index),
            icon: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFD0D0D0),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFD6D6D6), Color(0xFFAFAFAF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD6D6D6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MilestoneDialog extends StatefulWidget {
  final ClientMilestone? milestone;
  final Function(ClientMilestone) onSave;

  const _MilestoneDialog({this.milestone, required this.onSave});

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    if (widget.milestone != null) {
      _titleController.text = widget.milestone!.title;
      _amountController.text = widget.milestone!.amount.toString();
      _descriptionController.text = widget.milestone!.description ?? '';
      _isPaid = widget.milestone!.isPaid;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final milestone = ClientMilestone(
      id: widget.milestone?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isPaid: _isPaid,
      paidAt: _isPaid ? (widget.milestone?.paidAt ?? DateTime.now()) : null,
    );

    widget.onSave(milestone);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A1A), const Color(0xFF0D0D0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD6D6D6), Color(0xFFAFAFAF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.flag_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.milestone == null
                                  ? 'Add Milestone'
                                  : 'Edit Milestone',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),

                      // Title field
                      _buildDialogTextField(
                        controller: _titleController,
                        label: 'MILESTONE TITLE',
                        hint: 'Phase 1 - Design',
                        icon: Icons.edit_rounded,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),

                      const SizedBox(height: 20),

                      // Amount field
                      _buildDialogTextField(
                        controller: _amountController,
                        label: 'AMOUNT (USDT)',
                        hint: '1000.00',
                        icon: Icons.attach_money_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (double.tryParse(v!) == null)
                            return 'Invalid amount';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description field
                      _buildDialogTextField(
                        controller: _descriptionController,
                        label: 'DESCRIPTION (OPTIONAL)',
                        hint: 'Additional details about this milestone',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Paid toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: _isPaid
                                ? const Color(0xFFAFAFAF).withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isPaid
                                      ? [
                                          const Color(0xFFAFAFAF),
                                          const Color(
                                            0xFFAFAFAF,
                                          ).withOpacity(0.7),
                                        ]
                                      : [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mark as Paid',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isPaid,
                              onChanged: (value) =>
                                  setState(() => _isPaid = value),
                              activeColor: const Color(0xFFAFAFAF),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFD6D6D6),
                                    Color(0xFFAFAFAF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFD6D6D6,
                                    ).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Save Milestone',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(color: Color(0xFFD0D0D0)),
            ),
          ),
        ),
      ],
    );
  }
}
