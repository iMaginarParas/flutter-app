class Merchant {
  final String id;
  final String email;
  final String businessName;
  final String walletAddress;
  final String payoutAddress;
  final String apiKey;
  final String? webhookUrl;
  final bool isActive;
  final DateTime createdAt;

  Merchant({
    required this.id,
    required this.email,
    required this.businessName,
    required this.walletAddress,
    required this.payoutAddress,
    required this.apiKey,
    this.webhookUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'],
      email: json['email'],
      businessName: json['business_name'],
      walletAddress: json['wallet_address'],
      payoutAddress: json['payout_address'],
      apiKey: json['api_key'],
      webhookUrl: json['webhook_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'business_name': businessName,
      'wallet_address': walletAddress,
      'payout_address': payoutAddress,
      'api_key': apiKey,
      'webhook_url': webhookUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
