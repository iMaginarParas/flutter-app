import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/team.dart';
import '../services/storage_service.dart';

class FakeDataGenerator {
  static final _random = Random();
  static final _uuid = const Uuid();
  static final _storageService = StorageService();

  // Client names
  static final _clientNames = [
    'Tech Innovators Inc',
    'Digital Solutions Ltd',
    'Creative Agency Co',
    'Startup Ventures',
    'Global Trading Corp',
    'Marketing Masters',
    'Design Studio Pro',
    'Software Systems LLC',
    'Web Development Hub',
    'Mobile Apps Factory',
    'E-commerce Solutions',
    'Cloud Services Inc',
    'AI Research Labs',
    'Blockchain Ventures',
    'Crypto Holdings Ltd',
    'Finance Tech Group',
    'Healthcare Systems',
    'Education Platform',
    'Gaming Studios',
    'Media Productions',
  ];

  // Team member names and roles
  static final _teamMembers = [
    {'name': 'Test User 1', 'role': 'Senior Developer'},
    {'name': 'Test User 2', 'role': 'UI/UX Designer'},
    {'name': 'Test User 3', 'role': 'Full Stack Developer'},
    {'name': 'Test User 4', 'role': 'Project Manager'},
    {'name': 'Test User 5', 'role': 'DevOps Engineer'},
    {'name': 'Test User 6', 'role': 'Frontend Developer'},
    {'name': 'Test User 7', 'role': 'Backend Developer'},
    {'name': 'Test User 8', 'role': 'QA Engineer'},
    {'name': 'Test User 9', 'role': 'Mobile Developer'},
    {'name': 'Test User 10', 'role': 'Product Designer'},
    {'name': 'Test User 11', 'role': 'Data Scientist'},
    {'name': 'Test User 12', 'role': 'Marketing Manager'},
    {'name': 'Test User 13', 'role': 'Content Writer'},
    {'name': 'Test User 14', 'role': 'Business Analyst'},
    {'name': 'Test User 15', 'role': 'System Administrator'},
  ];

  // Milestone titles
  static final _milestones = [
    'Initial Design Phase',
    'Frontend Development',
    'Backend API Development',
    'Database Setup',
    'User Authentication',
    'Payment Integration',
    'Testing & QA',
    'Deployment Setup',
    'Final Delivery',
    'Mobile App Development',
    'Admin Dashboard',
    'Landing Page',
    'E-commerce Features',
    'Search Functionality',
    'Analytics Integration',
  ];

  // Generate random date within last 90 days
  static DateTime _randomDate() {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(90);
    return now.subtract(Duration(days: daysAgo, hours: _random.nextInt(24)));
  }

  // Generate random email
  static String _randomEmail(String name) {
    final domain = ['gmail.com', 'yahoo.com', 'outlook.com', 'company.com'][_random.nextInt(4)];
    return '${name.toLowerCase().replaceAll(' ', '.')}@$domain';
  }

  // Generate random phone
  static String _randomPhone() {
    return '+1${_random.nextInt(900) + 100}${_random.nextInt(900) + 100}${_random.nextInt(9000) + 1000}';
  }

  // Generate random wallet address
  static String _randomWallet() {
    const chars = '0123456789abcdef';
    return '0x${List.generate(40, (_) => chars[_random.nextInt(chars.length)]).join()}';
  }

  /// Generate fake clients with milestones
  static Future<void> generateFakeClients({int count = 10}) async {
    final clients = <Client>[];

    for (int i = 0; i < count; i++) {
      final createdAt = _randomDate();
      final clientName = _clientNames[i % _clientNames.length];

      // Generate 2-5 milestones per client
      final milestoneCount = 2 + _random.nextInt(4);
      final milestones = <ClientMilestone>[];

      for (int j = 0; j < milestoneCount; j++) {
        final amount = [500, 750, 1000, 1500, 2000, 2500, 3000, 4000, 5000, 7500][_random.nextInt(10)].toDouble();
        final isPaid = _random.nextDouble() > 0.3; // 70% chance of being paid
        final milestoneDate = createdAt.add(Duration(days: j * 7 + _random.nextInt(7)));

        milestones.add(ClientMilestone(
          id: _uuid.v4(),
          title: _milestones[_random.nextInt(_milestones.length)],
          amount: amount,
          description: 'Phase ${j + 1} of the project',
          isPaid: isPaid,
          paidAt: isPaid ? milestoneDate : null,
        ));
      }

      clients.add(Client(
        id: _uuid.v4(),
        name: clientName,
        email: _randomEmail(clientName),
        phone: _random.nextBool() ? _randomPhone() : null,
        telegramId: _random.nextBool() ? '@${clientName.toLowerCase().replaceAll(' ', '_')}' : null,
        walletAddress: _random.nextBool() ? _randomWallet() : null,
        createdAt: createdAt,
        milestones: milestones,
      ));
    }

    // Save clients
    final existingClients = await _storageService.getClients();
    await _storageService.saveClients([...existingClients, ...clients]);

    print('✅ Generated ${clients.length} fake clients with ${clients.fold(0, (sum, c) => sum + c.milestones.length)} milestones');
  }

  /// Generate fake team members with payments
  static Future<void> generateFakeTeamMembers({int count = 8}) async {
    final members = <TeamMember>[];

    for (int i = 0; i < count && i < _teamMembers.length; i++) {
      final memberData = _teamMembers[i];
      final createdAt = _randomDate();
      final salary = [500, 750, 1000, 1500, 2000, 2500, 3000, 4000][_random.nextInt(8)].toDouble();
      final salaryType = ['monthly', 'project'][_random.nextInt(2)];

      // Generate 1-5 payments per team member
      final paymentCount = 1 + _random.nextInt(5);
      final payments = <TeamPayment>[];

      for (int j = 0; j < paymentCount; j++) {
        final paymentDate = createdAt.add(Duration(days: j * 30 + _random.nextInt(30)));
        final isPaid = _random.nextDouble() > 0.6; // 40% chance of being paid (less than client payments)

        payments.add(TeamPayment(
          id: _uuid.v4(),
          teamMemberId: _uuid.v4(),
          amount: salaryType == 'monthly' ? salary : (salary * 0.25), // 25% installments for project
          description: salaryType == 'monthly'
              ? 'Monthly salary - ${_getMonthName(paymentDate.month)} ${paymentDate.year}'
              : 'Project installment ${j + 1}',
          isPaid: isPaid,
          paidAt: isPaid ? paymentDate : null,
          createdAt: paymentDate,
        ));
      }

      members.add(TeamMember(
        id: _uuid.v4(),
        name: memberData['name']!,
        email: _randomEmail(memberData['name']!),
        phone: _random.nextBool() ? _randomPhone() : null,
        role: memberData['role']!,
        salary: salary,
        salaryType: salaryType,
        walletAddress: _random.nextBool() ? _randomWallet() : null,
        telegramId: _random.nextBool() ? '@${memberData['name']!.toLowerCase().replaceAll(' ', '_')}' : null,
        isActive: _random.nextDouble() > 0.2, // 80% active
        createdAt: createdAt,
        payments: payments,
      ));
    }

    // Save team members
    final existingMembers = await _storageService.getTeamMembers();
    await _storageService.saveTeamMembers([...existingMembers, ...members]);

    print('✅ Generated ${members.length} fake team members with ${members.fold(0, (sum, m) => sum + m.payments.length)} payments');
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Clear all fake data
  static Future<void> clearAllData() async {
    await _storageService.saveClients([]);
    await _storageService.saveTeamMembers([]);
    print('✅ Cleared all data');
  }

  /// Generate complete fake dataset
  static Future<void> generateCompleteDataset({
    int clientCount = 15,
    int teamCount = 8,
  }) async {
    print('🚀 Generating fake data...');
    await generateFakeClients(count: clientCount);
    await generateFakeTeamMembers(count: teamCount);
    print('✅ Complete! Generated $clientCount clients and $teamCount team members');
  }
}
