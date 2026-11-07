import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/merchant.dart';
import '../models/client.dart';
import '../models/team.dart';

class StorageService {
  static const String _keyMerchant = 'merchant';
  static const String _keyPassword = 'password';
  static const String _keyClients = 'clients';
  static const String _keyTeamMembers = 'team_members';
  static const String _keyApiKey = 'api_key';

  // Save merchant and password (for login)
  Future<void> saveMerchantAuth(Merchant merchant, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMerchant, json.encode(merchant.toJson()));
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyApiKey, merchant.apiKey);
  }

  // Get saved merchant
  Future<Merchant?> getMerchant() async {
    final prefs = await SharedPreferences.getInstance();
    final merchantJson = prefs.getString(_keyMerchant);
    if (merchantJson == null) return null;
    return Merchant.fromJson(json.decode(merchantJson));
  }

  // Verify password
  Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_keyPassword);
    return savedPassword == password;
  }

  // Get API key
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final merchant = await getMerchant();
    return merchant != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMerchant);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyApiKey);
  }

  // Save clients
  Future<void> saveClients(List<Client> clients) async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = clients.map((c) => c.toJson()).toList();
    await prefs.setString(_keyClients, json.encode(clientsJson));
  }

  // Get clients
  Future<List<Client>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final clientsJson = prefs.getString(_keyClients);
    if (clientsJson == null) return [];
    final List<dynamic> decoded = json.decode(clientsJson);
    return decoded.map((c) => Client.fromJson(c)).toList();
  }

  // Add client
  Future<void> addClient(Client client) async {
    final clients = await getClients();
    clients.add(client);
    await saveClients(clients);
  }

  // Update client
  Future<void> updateClient(Client updatedClient) async {
    final clients = await getClients();
    final index = clients.indexWhere((c) => c.id == updatedClient.id);
    if (index != -1) {
      clients[index] = updatedClient;
      await saveClients(clients);
    }
  }

  // Delete client
  Future<void> deleteClient(String clientId) async {
    final clients = await getClients();
    clients.removeWhere((c) => c.id == clientId);
    await saveClients(clients);
  }

  // Team Members Methods
  Future<void> saveTeamMembers(List<TeamMember> members) async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = members.map((m) => m.toJson()).toList();
    await prefs.setString(_keyTeamMembers, json.encode(membersJson));
  }

  Future<List<TeamMember>> getTeamMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = prefs.getString(_keyTeamMembers);
    if (membersJson == null) return [];
    final List<dynamic> decoded = json.decode(membersJson);
    return decoded.map((m) => TeamMember.fromJson(m)).toList();
  }

  Future<void> addTeamMember(TeamMember member) async {
    final members = await getTeamMembers();
    members.add(member);
    await saveTeamMembers(members);
  }

  Future<void> updateTeamMember(TeamMember updatedMember) async {
    final members = await getTeamMembers();
    final index = members.indexWhere((m) => m.id == updatedMember.id);
    if (index != -1) {
      members[index] = updatedMember;
      await saveTeamMembers(members);
    }
  }

  Future<void> deleteTeamMember(String memberId) async {
    final members = await getTeamMembers();
    members.removeWhere((m) => m.id == memberId);
    await saveTeamMembers(members);
  }
}
