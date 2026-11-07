import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/fake_data_generator.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isGenerating = false;
  String _statusMessage = '';

  Future<void> _generateData({
    required int clientCount,
    required int teamCount,
  }) async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating data...';
    });

    try {
      await FakeDataGenerator.generateCompleteDataset(
        clientCount: clientCount,
        teamCount: teamCount,
      );

      setState(() {
        _statusMessage =
            '✅ Generated $clientCount clients and $teamCount team members!';
        _isGenerating = false;
      });

      // Show success dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => _buildSuccessDialog(clientCount, teamCount),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Clearing data...';
    });

    try {
      await FakeDataGenerator.clearAllData();

      setState(() {
        _statusMessage = '✅ All data cleared!';
        _isGenerating = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data cleared successfully!'),
          backgroundColor: const Color(0xFFAFAFAF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isGenerating = false;
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
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildPresetCard(
                      'Small Dataset',
                      '5 Clients + 3 Team Members',
                      'Quick test with minimal data',
                      const Color(0xFFD6D6D6),
                      Icons.data_usage_rounded,
                      () => _generateData(clientCount: 5, teamCount: 3),
                    ),
                    const SizedBox(height: 16),
                    _buildPresetCard(
                      'Medium Dataset',
                      '15 Clients + 8 Team Members',
                      'Recommended for testing',
                      const Color(0xFFAFAFAF),
                      Icons.analytics_rounded,
                      () => _generateData(clientCount: 15, teamCount: 8),
                    ),
                    const SizedBox(height: 16),
                    _buildPresetCard(
                      'Large Dataset',
                      '30 Clients + 15 Team Members',
                      'Full scale testing',
                      const Color(0xFFE0E0E0),
                      Icons.storage_rounded,
                      () => _generateData(clientCount: 30, teamCount: 15),
                    ),
                    const SizedBox(height: 32),
                    _buildDangerCard(),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildStatusCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD0D0D0), Color(0xFFEEEEEE)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bug_report_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Debug Tools',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD6D6D6).withOpacity(0.2),
            const Color(0xFFAFAFAF).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD6D6D6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD6D6D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fake Data Generator',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Generate test data with clients, milestones, team members, and payments',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard(
    String title,
    String subtitle,
    String description,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: _isGenerating ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD0D0D0).withOpacity(0.3),
          width: 1,
        ),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD0D0D0).withOpacity(0.1),
            const Color(0xFFD0D0D0).withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D0D0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD0D0D0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This will permanently delete all clients, team members, milestones, and payment records.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _clearData,
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Clear All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD0D0D0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A1A2E),
      ),
      child: Row(
        children: [
          if (_isGenerating)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Color(0xFFD6D6D6),
                strokeWidth: 2,
              ),
            )
          else
            Icon(
              _statusMessage.startsWith('✅')
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: _statusMessage.startsWith('✅')
                  ? const Color(0xFFAFAFAF)
                  : const Color(0xFFD0D0D0),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDialog(int clientCount, int teamCount) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            const Text(
              'Data Generated!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Successfully created:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    '👥 Clients',
                    '$clientCount',
                    const Color(0xFFD6D6D6),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '🤝 Team Members',
                    '$teamCount',
                    const Color(0xFFE0E0E0),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '🎯 Milestones',
                    '${clientCount * 3}~${clientCount * 5}',
                    const Color(0xFFAFAFAF),
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow(
                    '💰 Payments',
                    '${teamCount * 2}~${teamCount * 5}',
                    const Color(0xFFEEEEEE),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pop(true); // Return to previous screen with refresh
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6D6D6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
