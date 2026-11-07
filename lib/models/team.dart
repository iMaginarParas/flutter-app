class TeamMember {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final double salary;
  final String salaryType; // 'monthly' or 'project'
  final String? walletAddress;
  final String? telegramId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TeamPayment> payments;

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.salary,
    required this.salaryType,
    this.walletAddress,
    this.telegramId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.payments = const [],
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      salary: json['salary'].toDouble(),
      salaryType: json['salary_type'],
      walletAddress: json['wallet_address'],
      telegramId: json['telegram_id'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => TeamPayment.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'salary': salary,
      'salary_type': salaryType,
      'wallet_address': walletAddress,
      'telegram_id': telegramId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  double get totalPaid =>
      payments.where((p) => p.isPaid).fold(0, (sum, p) => sum + p.amount);

  double get pendingAmount => salaryType == 'monthly'
      ? salary
      : salary - totalPaid;
}

class TeamPayment {
  final String id;
  final String teamMemberId;
  final double amount;
  final String description;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  TeamPayment({
    required this.id,
    required this.teamMemberId,
    required this.amount,
    required this.description,
    this.isPaid = false,
    this.paidAt,
    required this.createdAt,
  });

  factory TeamPayment.fromJson(Map<String, dynamic> json) {
    return TeamPayment(
      id: json['id'],
      teamMemberId: json['team_member_id'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      isPaid: json['is_paid'] ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_member_id': teamMemberId,
      'amount': amount,
      'description': description,
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
