import 'package:flutter/material.dart';

enum ActivityType {
  invoice,
  clientPayment,
  teamPayment,
  clientCreated,
  teamMemberAdded,
}

class Activity {
  final String id;
  final ActivityType type;
  final String title;
  final String? subtitle;
  final double? amount;
  final String? status;
  final String? transactionHash;
  final DateTime createdAt;
  final IconData icon;
  final Color color;

  Activity({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.amount,
    this.status,
    this.transactionHash,
    required this.createdAt,
    required this.icon,
    required this.color,
  });

  static Activity fromInvoice(dynamic payment) {
    final rawStatus = (payment.status as String).toLowerCase();
    final invoiceId = payment.id as String;
    final shortInvoiceId = invoiceId.substring(
      0,
      invoiceId.length < 8 ? invoiceId.length : 8,
    );
    final invoiceStatus = switch (rawStatus) {
      'created' || 'pending' => 'pending',
      'confirmed' || 'paid' => 'paid',
      _ => rawStatus,
    };

    return Activity(
      id: payment.id,
      type: ActivityType.invoice,
      title: payment.description ?? 'Invoice Payment',
      subtitle: 'Invoice #$shortInvoiceId',
      amount: double.tryParse(payment.amount) ?? 0.0,
      status: invoiceStatus,
      transactionHash: payment.txHash,
      createdAt: payment.createdAt,
      icon: Icons.receipt_long_rounded,
      color: Colors.white,
    );
  }

  static Activity fromClientMilestone(String clientName, dynamic milestone) {
    return Activity(
      id: milestone.id,
      type: ActivityType.clientPayment,
      title: milestone.title,
      subtitle: 'Client: $clientName',
      amount: milestone.amount,
      status: milestone.isPaid ? 'paid' : 'pending',
      createdAt: milestone.paidAt ?? DateTime.now(),
      icon: Icons.flag_rounded,
      color: Colors.white70,
    );
  }

  static Activity fromTeamPayment(
    String memberName,
    String role,
    dynamic payment,
  ) {
    return Activity(
      id: payment.id,
      type: ActivityType.teamPayment,
      title: payment.description,
      subtitle: '$memberName - $role',
      amount: payment.amount,
      status: payment.isPaid ? 'paid' : 'pending',
      createdAt: payment.paidAt ?? payment.createdAt,
      icon: Icons.people_rounded,
      color: Colors.white60,
    );
  }

  static Activity fromClientCreated(String clientName, DateTime createdAt) {
    return Activity(
      id: createdAt.toString(),
      type: ActivityType.clientCreated,
      title: 'New client added',
      subtitle: clientName,
      createdAt: createdAt,
      icon: Icons.person_add_rounded,
      color: Colors.white54,
    );
  }

  static Activity fromTeamMemberAdded(
    String memberName,
    String role,
    DateTime createdAt,
  ) {
    return Activity(
      id: createdAt.toString(),
      type: ActivityType.teamMemberAdded,
      title: 'New team member',
      subtitle: '$memberName - $role',
      createdAt: createdAt,
      icon: Icons.group_add_rounded,
      color: Colors.white38,
    );
  }

  String get displayAmount {
    if (amount == null) return '';
    return '\$${amount!.toStringAsFixed(2)}';
  }

  String get displayStatus {
    if (status == null) return '';
    return status!.toUpperCase();
  }

  Color get statusColor {
    if (status == null) return Colors.grey;
    switch (status!.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        return Colors.white;
      case 'pending':
      case 'created':
        return Colors.white70;
      case 'failed':
        return Colors.white38;
      default:
        return Colors.grey;
    }
  }
}
