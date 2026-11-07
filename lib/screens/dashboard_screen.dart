import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/payment.dart';
import '../models/activity.dart';
import '../models/client.dart';
import '../models/team.dart';
import 'create_invoice_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String apiKey;
  final bool isActive;

  const DashboardScreen({
    super.key,
    required this.apiKey,
    this.isActive = true,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final _apiService = ApiService();
  final _storageService = StorageService();
  final _scrollController = ScrollController();
  final _activitySectionKey = GlobalKey();
  Timer? _statusRefreshTimer;
  bool _isFetching = false;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  List<Payment> _payments = [];
  final Map<String, Payment> _recentlyCreatedPayments = {};
  List<Activity> _allActivities = [];
  bool _isLoading = true;
  String? _merchantName;
  double _totalBalance = 0.0;
  double _totalReceived = 0.0; // From invoices and client payments
  double _totalPaid = 0.0; // To team members
  int _paidCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _syncStatusRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncStatusRefreshTimer();
      if (widget.isActive) _loadData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    _syncStatusRefreshTimer();
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _loadData();
    }
  }

  void _syncStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    if (!widget.isActive || _appLifecycleState != AppLifecycleState.resumed) {
      return;
    }

    _statusRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadData(),
    );
  }

  Future<void> _loadData() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _merchantName = prefs.getString('merchant_name');
      });

      // Load all data in parallel
      final results = await Future.wait([
        _apiService.listPayments(widget.apiKey).catchError((_) => <Payment>[]),
        _storageService.getClients().catchError((_) => <Client>[]),
        _storageService.getTeamMembers().catchError((_) => <TeamMember>[]),
      ]);

      final apiPayments = results[0] as List<Payment>;
      final payments = [
        ...apiPayments,
        ..._recentlyCreatedPayments.values.where(
          (localPayment) => !apiPayments.any(
            (apiPayment) => apiPayment.id == localPayment.id,
          ),
        ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final clients = results[1] as List;
      final teamMembers = results[2] as List;

      // Calculate stats
      double totalReceived = 0.0;
      double totalPaidOut = 0.0;
      int paid = 0;
      int pending = 0;

      // Count invoice payments
      for (var payment in payments) {
        if (payment.status == 'confirmed' || payment.status == 'paid') {
          totalReceived += double.tryParse(payment.amount) ?? 0.0;
          paid++;
        } else if (payment.status == 'pending' || payment.status == 'created') {
          pending++;
        }
      }

      // Add client milestone payments
      for (var client in clients) {
        for (var milestone in client.milestones) {
          if (milestone.isPaid) {
            totalReceived += milestone.amount;
          }
        }
      }

      // Subtract team payments
      for (var member in teamMembers) {
        for (var payment in member.payments) {
          if (payment.isPaid) {
            totalPaidOut += payment.amount;
          }
        }
      }

      final totalBalance = totalReceived - totalPaidOut;

      // Build unified activity list
      List<Activity> activities = [];

      // Add invoices
      for (var payment in payments) {
        activities.add(Activity.fromInvoice(payment));
      }

      // Add client milestones
      for (var client in clients) {
        for (var milestone in client.milestones) {
          if (milestone.isPaid) {
            activities.add(
              Activity.fromClientMilestone(client.name, milestone),
            );
          }
        }
        // Add client creation
        activities.add(
          Activity.fromClientCreated(client.name, client.createdAt),
        );
      }

      // Add team payments
      for (var member in teamMembers) {
        for (var payment in member.payments) {
          if (payment.isPaid) {
            activities.add(
              Activity.fromTeamPayment(member.name, member.role, payment),
            );
          }
        }
        // Add team member addition
        activities.add(
          Activity.fromTeamMemberAdded(
            member.name,
            member.role,
            member.createdAt,
          ),
        );
      }

      // Sort by date (newest first)
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _payments = payments;
        _allActivities = activities;
        _totalBalance = totalBalance;
        _totalReceived = totalReceived;
        _totalPaid = totalPaidOut;
        _paidCount = paid;
        _pendingCount = pending;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  void _handleInvoiceResult(Object? result) {
    if (result is Payment) {
      _recentlyCreatedPayments[result.id] = result;
      final activities = [
        Activity.fromInvoice(result),
        ..._allActivities.where((activity) => activity.id != result.id),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _allActivities = activities;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final sectionContext = _activitySectionKey.currentContext;
        if (sectionContext != null) {
          Scrollable.ensureVisible(
            sectionContext,
            alignment: 0.08,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        }
      });
      _loadData();
    } else if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 72,
        titleSpacing: 20,
        backgroundColor: const Color(0xFF000000),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                'assets/logo.png',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pocket Pay',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Get paid globally in USDT',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white54,
            size: 21,
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                (_merchantName ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.white,
          backgroundColor: const Color(0xFF171717),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: _isLoading
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                minHeight: 2,
                                backgroundColor: Color(0xFF242424),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 0),
                  ),
                  const SizedBox(height: 12),

                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Wallet illustration on right
                        Positioned(
                          right: -10,
                          top: 5,
                          child: Opacity(
                            opacity: 0.2,
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Balance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(
                                  Icons.visibility_outlined,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.12),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                '\$${_totalBalance.toStringAsFixed(2)} USDT',
                                key: ValueKey(_totalBalance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    const Text(
                                      'On Whitechain',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Create Invoice',
                          Icons.add_rounded,
                          Colors.white,
                          () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateInvoiceScreen(apiKey: widget.apiKey),
                              ),
                            );
                            _handleInvoiceResult(result);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Payment Link',
                          Icons.link_rounded,
                          Colors.white70,
                          () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A1A),
                                title: const Text(
                                  'Payment Link',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Payment link feature coming soon!',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Received',
                          '\$${_totalReceived.toStringAsFixed(0)}',
                          Icons.arrow_downward_rounded,
                          Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Paid Out',
                          '\$${_totalPaid.toStringAsFixed(0)}',
                          Icons.arrow_upward_rounded,
                          Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Invoices',
                          _payments.length.toString(),
                          Icons.receipt_long_rounded,
                          Colors.white60,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Revenue Overview
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bar_chart_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Revenue Overview',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Last 30 Days',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No data yet',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Create an invoice to see your revenue',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Activity
                  Row(
                    key: _activitySectionKey,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A1A),
                              title: const Text(
                                'All Activities',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 400,
                                child: ListView.builder(
                                  itemCount: _allActivities.length,
                                  itemBuilder: (context, index) {
                                    return _buildActivityCard(
                                      _allActivities[index],
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Activity List
                  if (_allActivities.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 44,
                            color: Colors.white.withOpacity(0.18),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No activity yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start by creating an invoice or adding a client',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._allActivities.take(10).map((activity) {
                      return _buildActivityCard(activity);
                    }).toList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateInvoiceScreen(apiKey: widget.apiKey),
            ),
          );
          _handleInvoiceResult(result);
        },
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text(
          'Create Invoice',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.065)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.58), size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 8, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.065)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.42), size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.055)),
        ),
        child: Row(
          children: [
            Icon(
              activity.icon,
              color: Colors.white.withOpacity(0.42),
              size: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.82),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (activity.subtitle != null) ...[
                        Flexible(
                          child: Text(
                            activity.subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                      Text(
                        _formatDate(activity.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (activity.amount != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    activity.displayAmount,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (activity.status != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        activity.displayStatus,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                  if (activity.transactionHash != null &&
                      activity.status == 'paid') ...[
                    const SizedBox(height: 4),
                    Tooltip(
                      message: activity.transactionHash!,
                      child: InkWell(
                        onTap: () =>
                            _openTransaction(activity.transactionHash!),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 10,
                                color: Colors.white.withOpacity(0.55),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'TX',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _compactTransactionHash(
                                  activity.transactionHash!,
                                ),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.white;
      case 'pending':
        return Colors.white70;
      case 'failed':
        return Colors.white38;
      default:
        return Colors.white;
    }
  }

  Future<void> _openTransaction(String transactionHash) async {
    final explorerUri = Uri.parse(
      'https://explorer.testnet.whitechain.io/tx/$transactionHash',
    );
    final opened = await launchUrl(
      explorerUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the Whitechain explorer.'),
          backgroundColor: Color(0xFF242424),
        ),
      );
    }
  }

  String _compactTransactionHash(String transactionHash) {
    if (transactionHash.length <= 16) return transactionHash;
    return '${transactionHash.substring(0, 8)}…${transactionHash.substring(transactionHash.length - 6)}';
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
