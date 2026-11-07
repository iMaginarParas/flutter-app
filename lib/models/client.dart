class ClientMilestone {
  final String id;
  final String title;
  final double amount;
  final String? description;
  final bool isPaid;
  final DateTime? paidAt;

  ClientMilestone({
    required this.id,
    required this.title,
    required this.amount,
    this.description,
    this.isPaid = false,
    this.paidAt,
  });

  factory ClientMilestone.fromJson(Map<String, dynamic> json) {
    return ClientMilestone(
      id: json['id'],
      title: json['title'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      isPaid: json['is_paid'] ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'description': description,
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? telegramId;
  final String? walletAddress;
  final List<ClientMilestone> milestones;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.telegramId,
    this.walletAddress,
    this.milestones = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      telegramId: json['telegram_id'],
      walletAddress: json['wallet_address'],
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((m) => ClientMilestone.fromJson(m))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'telegram_id': telegramId,
      'wallet_address': walletAddress,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get totalAmount =>
      milestones.fold(0, (sum, milestone) => sum + milestone.amount);

  double get paidAmount => milestones
      .where((m) => m.isPaid)
      .fold(0, (sum, milestone) => sum + milestone.amount);

  double get remainingAmount => totalAmount - paidAmount;
}
