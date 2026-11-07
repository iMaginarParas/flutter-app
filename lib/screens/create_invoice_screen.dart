import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../models/payment.dart';
import '../models/client.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String apiKey;

  const CreateInvoiceScreen({super.key, required this.apiKey});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _pdfService = PdfService();
  bool _isCreating = false;
  bool _isGeneratingPdf = false;
  Payment? _createdPayment;
  File? _pdfFile;
  List<Client> _clients = [];
  Client? _selectedClient;
  ClientMilestone? _selectedMilestone;
  bool _isLoadingClients = true;
  String? _merchantName;
  String? _merchantEmail;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _loadMerchantInfo();
  }

  Future<void> _loadMerchantInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _merchantName = prefs.getString('merchant_name') ?? 'Business';
      _merchantEmail = prefs.getString('merchant_email') ?? '';
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _storageService.getClients();
      setState(() {
        _clients = clients;
        _isLoadingClients = false;
      });
    } catch (e) {
      setState(() => _isLoadingClients = false);
    }
  }

  void _selectClient(Client? client) {
    setState(() {
      _selectedClient = client;
      _selectedMilestone = null;
      if (client == null) {
        _amountController.clear();
        _descriptionController.clear();
      }
    });
  }

  void _selectMilestone(ClientMilestone? milestone) {
    setState(() {
      _selectedMilestone = milestone;
      if (milestone != null) {
        _amountController.text = milestone.amount.toString();
        _descriptionController.text = milestone.title;
        if (_selectedClient != null) {
          _orderIdController.text = 'Client: ${_selectedClient!.name}';
        }
      }
    });
  }

  Future<void> _generatePdf() async {
    if (_createdPayment == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final pdfFile = await _pdfService.generateInvoicePdf(
        payment: _createdPayment!,
        merchantName: _merchantName ?? 'Business',
        merchantEmail: _merchantEmail ?? '',
        client: _selectedClient,
        milestone: _selectedMilestone,
      );

      setState(() {
        _pdfFile = pdfFile;
        _isGeneratingPdf = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF invoice generated successfully!'),
            backgroundColor: Colors.white,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.white70,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) {
      await _generatePdf();
      if (_pdfFile == null) return;
    }

    try {
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        subject: 'Invoice ${_createdPayment?.paymentId}',
        text:
            'Please find attached your invoice from ${_merchantName ?? 'our business'}.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            backgroundColor: Colors.white70,
          ),
        );
      }
    }
  }

  Future<void> _createInvoice() async {
    // Check if form state exists and validate
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      print('❌ Form validation failed or form not ready');
      return;
    }

    print('✅ Form validated, creating invoice...');

    setState(() {
      _isCreating = true;
    });

    try {
      final payment = await _apiService.createPayment(
        apiKey: widget.apiKey,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        orderId: _orderIdController.text.isEmpty
            ? null
            : _orderIdController.text,
      );

      setState(() {
        _createdPayment = payment;
        _currentStep = 2;
      });

      // Mark milestone as paid if one was selected
      if (_selectedClient != null && _selectedMilestone != null) {
        final updatedMilestones = _selectedClient!.milestones.map((m) {
          if (m.id == _selectedMilestone!.id) {
            return ClientMilestone(
              id: m.id,
              title: m.title,
              amount: m.amount,
              description: m.description,
              isPaid: true,
              paidAt: DateTime.now(),
            );
          }
          return m;
        }).toList();

        final updatedClient = Client(
          id: _selectedClient!.id,
          name: _selectedClient!.name,
          email: _selectedClient!.email,
          phone: _selectedClient!.phone,
          telegramId: _selectedClient!.telegramId,
          walletAddress: _selectedClient!.walletAddress,
          milestones: updatedMilestones,
          createdAt: _selectedClient!.createdAt,
          updatedAt: DateTime.now(),
        );

        await _storageService.updateClient(updatedClient);
      }

      await Clipboard.setData(ClipboardData(text: payment.checkoutUrl ?? ''));

      // Generate PDF automatically
      await _generatePdf();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.white70,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, _createdPayment),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Invoice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Step Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Details'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 1
                          ? const Color(0xFFD6D6D6)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  _buildStepIndicator(1, 'Review'),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 2
                          ? const Color(0xFFD6D6D6)
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  _buildStepIndicator(2, 'Share'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFD6D6D6) : const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? const Color(0xFFD6D6D6) : Colors.transparent,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildReviewStep();
      case 2:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact Invoice Details Card
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
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Invoice Details',
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
                          // Client & Milestone Selection
                          if (!_isLoadingClients && _clients.isNotEmpty) ...[
                            _buildCompactDropdown<Client>(
                              label: 'CLIENT',
                              value: _selectedClient,
                              hint: 'Select client',
                              icon: Icons.person_outline_rounded,
                              items: [
                                const DropdownMenuItem<Client>(
                                  value: null,
                                  child: Text('Manual Entry'),
                                ),
                                ..._clients.map(
                                  (client) => DropdownMenuItem(
                                    value: client,
                                    child: Text(client.name),
                                  ),
                                ),
                              ],
                              onChanged: _selectClient,
                            ),
                            if (_selectedClient != null &&
                                _selectedClient!.milestones.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildCompactDropdown<ClientMilestone>(
                                label: 'MILESTONE',
                                value: _selectedMilestone,
                                hint: 'Select milestone',
                                icon: Icons.flag_outlined,
                                items: [
                                  const DropdownMenuItem<ClientMilestone>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ..._selectedClient!.milestones
                                      .where((m) => !m.isPaid)
                                      .map(
                                        (milestone) => DropdownMenuItem(
                                          value: milestone,
                                          child: Text(
                                            '${milestone.title} - \$${milestone.amount}',
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: _selectMilestone,
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                          _buildCompactInvoiceField(
                            controller: _amountController,
                            label: 'AMOUNT',
                            hint: '0.00',
                            icon: Icons.attach_money_rounded,
                            suffix: 'USDT',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              if (double.tryParse(v!) == null) return 'Invalid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildCompactInvoiceField(
                            controller: _descriptionController,
                            label: 'DESCRIPTION',
                            hint: 'Service description',
                            icon: Icons.description_rounded,
                            maxLines: 2,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          _buildCompactInvoiceField(
                            controller: _orderIdController,
                            label: 'ORDER ID',
                            hint: 'ORD-123 (optional)',
                            icon: Icons.tag_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Create Button
            _buildCompactGradientButton(
              label: 'Create Invoice',
              icon: Icons.receipt_long_rounded,
              isLoading: _isCreating,
              onPressed: _isCreating
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await _createInvoice();
                      }
                    },
            ),
          ],
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

  Widget _buildCompactInvoiceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
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
            maxLines: maxLines,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                fontSize: 12,
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

  Widget _buildCompactDropdown<T>({
    required String label,
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              value: value,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
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
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactGradientButton({
    required String label,
    required IconData icon,
    bool isLoading = false,
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
        child: isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInvoiceField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(color: Color(0xFFD0D0D0)),
              errorMaxLines: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyledDropdown<T>({
    required String label,
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              value: value,
              dropdownColor: const Color(0xFF1A1A1A),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.5),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    bool isLoading = false,
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
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD6D6D6), Color(0xFFBDBDBD)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Invoice Amount',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_amountController.text} USDT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_selectedClient != null) ...[
            _buildInfoRow('Client', _selectedClient!.name),
            const SizedBox(height: 16),
            if (_selectedClient!.email.isNotEmpty)
              _buildInfoRow('Email', _selectedClient!.email),
            if (_selectedClient!.email.isNotEmpty) const SizedBox(height: 16),
          ],
          if (_selectedMilestone != null) ...[
            _buildInfoRow('Milestone', _selectedMilestone!.title),
            const SizedBox(height: 16),
          ],
          _buildInfoRow('Description', _descriptionController.text),
          if (_orderIdController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', _orderIdController.text),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isCreating ? null : _createInvoice,
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Create Invoice'),
                      SizedBox(width: 8),
                      Icon(Icons.check_rounded, size: 20),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Success Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFAFAFAF).withOpacity(0.2),
                  const Color(0xFFAFAFAF).withOpacity(0.05),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFAFAFAF), Color(0xFFD6D6D6)],
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Invoice Created!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            '\$${_createdPayment?.amount} USDT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // QR Code Card
          Expanded(
            child: _buildGlassCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_createdPayment?.checkoutUrl != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: _createdPayment!.checkoutUrl!,
                        version: QrVersions.auto,
                        size: 140.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAFAFAF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFAFAFAF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFAFAFAF),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Link copied!',
                          style: TextStyle(
                            color: Color(0xFFAFAFAF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildCompactGradientButton(
                  label: _isGeneratingPdf ? 'PDF...' : 'PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  isLoading: _isGeneratingPdf,
                  onPressed: _isGeneratingPdf ? null : _sharePdf,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    if (_createdPayment?.checkoutUrl != null) {
                      Clipboard.setData(
                        ClipboardData(text: _createdPayment!.checkoutUrl!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link copied!'),
                          backgroundColor: const Color(0xFFAFAFAF),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'Copy',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.pop(context, _createdPayment),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Back to Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
