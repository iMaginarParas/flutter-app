import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/merchant.dart';
import '../models/payment.dart';

class ApiService {
  static const String baseUrl = 'https://web-production-7892c.up.railway.app';

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check backend health');
    }
  }

  // Login merchant
  Future<Merchant> loginMerchant({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl/api/merchants/login';
    print('🔵 [API] POST $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    print('🔵 [API] Response Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return Merchant.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to login');
    }
  }

  // Create merchant
  Future<Merchant> createMerchant({
    required String name,
    required String email,
    required String payoutAddress,
    required String password,
    String? webhookUrl,
  }) async {
    final url = '$baseUrl/api/merchants/register';
    print('🔵 [API] POST $url');
    print(
      '🔵 [API] Body: ${json.encode({'business_name': name, 'email': email, 'wallet_address': payoutAddress, 'payout_address': payoutAddress, 'password': password, if (webhookUrl != null) 'webhook_url': webhookUrl})}',
    );

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'business_name': name,
        'email': email,
        'wallet_address': payoutAddress,
        'payout_address': payoutAddress,
        'password': password,
        if (webhookUrl != null) 'webhook_url': webhookUrl,
      }),
    );

    print('🔵 [API] Response Status: ${response.statusCode}');
    print('🔵 [API] Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return Merchant.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create merchant');
    }
  }

  // Get merchant by API key
  Future<Merchant> getMerchant(String apiKey) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/merchants/me'),
      headers: {'X-API-Key': apiKey},
    );

    if (response.statusCode == 200) {
      return Merchant.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get merchant');
    }
  }

  Future<Merchant> updateMerchant({
    required String apiKey,
    required String businessName,
    required String email,
    required String payoutAddress,
    String? webhookUrl,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/merchants/me'),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: json.encode({
        'business_name': businessName,
        'email': email,
        'wallet_address': payoutAddress,
        'payout_address': payoutAddress,
        'webhook_url': webhookUrl,
      }),
    );

    if (response.statusCode == 200) {
      return Merchant.fromJson(json.decode(response.body));
    }

    final error = json.decode(response.body);
    throw Exception(error['detail'] ?? 'Failed to update business details');
  }

  // Create payment
  Future<Payment> createPayment({
    required String apiKey,
    required double amount,
    required String description,
    String? orderId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final url = '$baseUrl/api/payments/checkout/create';
    print('🟢 [API] POST $url');
    print('🟢 [API] Headers: X-API-Key: ${apiKey.substring(0, 20)}...');
    print(
      '🟢 [API] Body: ${json.encode({'amount': amount.toString(), 'description': description, if (orderId != null) 'order_id': orderId, if (successUrl != null) 'success_url': successUrl, if (cancelUrl != null) 'cancel_url': cancelUrl})}',
    );

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: json.encode({
        'amount': amount.toString(), // Backend expects string
        'description': description,
        if (orderId != null) 'order_id': orderId,
        if (successUrl != null) 'success_url': successUrl,
        if (cancelUrl != null) 'cancel_url': cancelUrl,
      }),
    );

    print('🟢 [API] Response Status: ${response.statusCode}');
    print('🟢 [API] Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return Payment.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create payment');
    }
  }

  // Get payment by ID
  Future<Payment> getPayment(String paymentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/payments/$paymentId'),
    );

    if (response.statusCode == 200) {
      return Payment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get payment');
    }
  }

  // List merchant payments
  Future<List<Payment>> listPayments(String apiKey) async {
    final url = '$baseUrl/api/payments/';
    print('🟡 [API] GET $url');
    print('🟡 [API] Headers: X-API-Key: ${apiKey.substring(0, 20)}...');

    final response = await http.get(
      Uri.parse(url),
      headers: {'X-API-Key': apiKey},
    );

    print('🟡 [API] Response Status: ${response.statusCode}');
    print('🟡 [API] Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Payment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to list payments');
    }
  }
}
