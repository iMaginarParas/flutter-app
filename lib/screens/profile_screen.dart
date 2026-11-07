import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/merchant.dart';
import '../models/payment.dart';
import 'onboarding_screen.dart';
import 'debug_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String apiKey;

  const ProfileScreen({super.key, required this.apiKey});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  String? _merchantName;
  String? _merchantEmail;
  String? _payoutAddress;
  String? _webhookUrl;
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _merchantName = prefs.getString('merchant_name');
      _merchantEmail = prefs.getString('merchant_email');
    });

    try {
      final merchant = await _apiService.getMerchant(widget.apiKey);
      if (!mounted) return;
      setState(() {
        _merchantName = merchant.businessName;
        _merchantEmail = merchant.email;
        _payoutAddress = merchant.payoutAddress;
        _webhookUrl = merchant.webhookUrl;
      });
      await prefs.setString('merchant_name', merchant.businessName);
      await prefs.setString('merchant_email', merchant.email);
    } catch (_) {
      // Keep the last locally saved name and email when offline.
    }

    try {
      final payments = await _apiService.listPayments(widget.apiKey);
      if (!mounted) return;
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editBusinessDetails() async {
    final formKey = GlobalKey<FormState>();
    final businessNameController = TextEditingController(
      text: _merchantName ?? '',
    );
    final emailController = TextEditingController(text: _merchantEmail ?? '');
    final payoutAddressController = TextEditingController(
      text: _payoutAddress ?? '',
    );
    final webhookController = TextEditingController(text: _webhookUrl ?? '');
    String? saveError;

    final updatedMerchant = await showDialog<Merchant>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Edit business details',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: businessNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Business name',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a business name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Business email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: payoutAddressController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Payout wallet address',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (value) =>
                          value == null ||
                              !value.startsWith('0x') ||
                              value.length != 42
                          ? 'Enter a valid 0x wallet address'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: webhookController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Webhook URL (optional)',
                        prefixIcon: Icon(Icons.webhook_outlined),
                      ),
                    ),
                    if (saveError != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          saveError!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saveError = null);
                try {
                  final merchant = await _apiService.updateMerchant(
                    apiKey: widget.apiKey,
                    businessName: businessNameController.text.trim(),
                    email: emailController.text.trim(),
                    payoutAddress: payoutAddressController.text.trim(),
                    webhookUrl: webhookController.text.trim().isEmpty
                        ? null
                        : webhookController.text.trim(),
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, merchant);
                  }
                } catch (error) {
                  setDialogState(() => saveError = error.toString());
                }
              },
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );

    businessNameController.dispose();
    emailController.dispose();
    payoutAddressController.dispose();
    webhookController.dispose();

    if (updatedMerchant == null || !mounted) return;
    setState(() {
      _merchantName = updatedMerchant.businessName;
      _merchantEmail = updatedMerchant.email;
      _payoutAddress = updatedMerchant.payoutAddress;
      _webhookUrl = updatedMerchant.webhookUrl;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('merchant_name', updatedMerchant.businessName);
    await prefs.setString('merchant_email', updatedMerchant.email);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildBusinessDetail(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value?.isNotEmpty == true ? value! : 'Not set',
          style: TextStyle(
            color: value?.isNotEmpty == true
                ? Colors.white.withOpacity(0.84)
                : Colors.white38,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'created':
        return Colors.white;
      case 'pending':
        return Colors.white70;
      case 'confirmed':
        return Colors.white;
      case 'failed':
        return Colors.white38;
      case 'expired':
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Picture
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: Text(
                          (_merchantName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _merchantName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _merchantEmail ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Debug Tools Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebugScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        icon: const Icon(
                          Icons.bug_report_rounded,
                          size: 20,
                          color: Colors.black,
                        ),
                        label: const Text(
                          'Debug Tools (Generate Fake Data)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Business Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _editBusinessDetails,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildBusinessDetail('Business name', _merchantName),
                      const SizedBox(height: 12),
                      _buildBusinessDetail('Email', _merchantEmail),
                      const SizedBox(height: 12),
                      _buildBusinessDetail('Payout wallet', _payoutAddress),
                      if (_webhookUrl?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _buildBusinessDetail('Webhook URL', _webhookUrl),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Payment History Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text(
                  'Payment History',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Payment History List
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD6D6D6)),
                ),
              )
            else if (_payments.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment history',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final payment = _payments[index];
                  return _buildPaymentItem(payment);
                }, childCount: _payments.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    final color = _getStatusColor(payment.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payment.description ?? 'No description',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${payment.amount} USDT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDate(payment.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
