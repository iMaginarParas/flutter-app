class Payment {
  final String id;
  final String paymentId;
  final String? merchantId;
  final String amount;
  final String currency;
  final String status;
  final String? payerAddress;
  final String? txHash;
  final String? description;
  final String? orderId;
  final String? checkoutUrl;
  final String? successUrl;
  final String? cancelUrl;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  Payment({
    required this.id,
    required this.paymentId,
    this.merchantId,
    required this.amount,
    required this.currency,
    required this.status,
    this.payerAddress,
    this.txHash,
    this.description,
    this.orderId,
    this.checkoutUrl,
    this.successUrl,
    this.cancelUrl,
    required this.createdAt,
    this.paidAt,
    this.expiresAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      paymentId: json['payment_id'],
      merchantId: json['merchant_id'],
      amount: json['amount'],
      currency: json['currency'] ?? 'USDT',
      status: json['status'],
      payerAddress: json['payer_address'],
      txHash: json['tx_hash'],
      description: json['description'],
      orderId: json['order_id'],
      checkoutUrl: json['checkout_url'],
      successUrl: json['success_url'],
      cancelUrl: json['cancel_url'],
      createdAt: DateTime.parse(json['created_at']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_id': paymentId,
      'merchant_id': merchantId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payer_address': payerAddress,
      'tx_hash': txHash,
      'description': description,
      'order_id': orderId,
      'checkout_url': checkoutUrl,
      'success_url': successUrl,
      'cancel_url': cancelUrl,
      'created_at': createdAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}
