import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _walletController = TextEditingController();
  final _webhookController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _backendStatus;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    try {
      final status = await _apiService.healthCheck();
      setState(() {
        _backendStatus = status;
      });
    } catch (e) {
      // Backend not available
    }
  }

  Future<void> _createMerchant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final merchant = await _apiService.createMerchant(
        name: _nameController.text,
        email: _emailController.text,
        payoutAddress: _walletController.text,
        webhookUrl: _webhookController.text.isEmpty
            ? null
            : _webhookController.text,
      );

      // Save API key
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', merchant.apiKey);
      await prefs.setString('merchant_name', merchant.name);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(apiKey: merchant.apiKey),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFF242424),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.payment_rounded,
                            color: Colors.black,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'PAYLINK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 42),
                    Text(
                      'PAYMENTS,\nWITHOUT FRICTION.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Accept USDT payments on Whitechain with simple, secure infrastructure built for Web3 merchants.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.62),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                    if (_backendStatus != null) ...[
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          border: Border.all(
                            color: Colors.white.withOpacity(.12),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.white,
                              size: 7,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Backend: ${_backendStatus!['status']}  ·  Chain ID: ${_backendStatus!['chain_id']}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(.1)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'GET STARTED',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                          labelStyle: TextStyle(color: Colors.white54),
                          prefixIconColor: Colors.white54,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(color: Color(0xFF292929)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter business name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                          labelStyle: TextStyle(color: Colors.white54),
                          prefixIconColor: Colors.white54,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(color: Color(0xFF292929)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _walletController,
                        decoration: const InputDecoration(
                          labelText: 'Payout Wallet Address',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                          labelStyle: TextStyle(color: Colors.white54),
                          prefixIconColor: Colors.white54,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(color: Color(0xFF292929)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter wallet address';
                          }
                          if (!value.startsWith('0x') || value.length != 42) {
                            return 'Please enter valid Ethereum address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _webhookController,
                        decoration: const InputDecoration(
                          labelText: 'Webhook URL (Optional)',
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFF1A1A1A),
                          labelStyle: TextStyle(color: Colors.white54),
                          prefixIconColor: Colors.white54,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(color: Color(0xFF292929)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(13)),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                          prefixIcon: Icon(Icons.webhook),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createMerchant,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Merchant Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: .2,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _walletController.dispose();
    _webhookController.dispose();
    super.dispose();
  }
}
