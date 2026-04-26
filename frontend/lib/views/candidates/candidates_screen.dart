import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/connection_service.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg = const Color(0xFFF5F7FF);
  
  List<Map<String, dynamic>> candidates = [];
  bool isLoading = true;
  bool hasError = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
        return decoded['sub'];
      }
    } catch (e) {
      print('Error decoding token: $e');
    }
    return null;
  }

  Future<void> _loadCandidates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      // Get current user ID
      currentUserId = await _getCurrentUserId();
      print('Current user ID: $currentUserId');
      
      // Get all users
      final usersResponse = await http.get(
        Uri.parse('http://localhost:8001/api/users/all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Users response: ${usersResponse.statusCode}');

      if (usersResponse.statusCode != 200) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      // Get all connections (accepted)
      final acceptedResult = await ConnectionService.getMyConnections();
      print('Accepted result: $acceptedResult');
      
      final acceptedConnectionIds = <String>{};
      if (acceptedResult is List) {
        for (var conn in acceptedResult) {
          final senderId = conn['sender_id'];
          final receiverId = conn['receiver_id'];
          acceptedConnectionIds.add(senderId);
          acceptedConnectionIds.add(receiverId);
        }
      }

      // Get all pending requests (both sent and received)
      final pendingResult = await ConnectionService.getPendingRequests();
      print('Pending result: $pendingResult');
      
      final pendingUserIds = <String>{};
      if (pendingResult is Map && pendingResult.containsKey('requests')) {
        for (var req in (pendingResult['requests'] ?? [])) {
          pendingUserIds.add(req['sender_id']);
          pendingUserIds.add(req['receiver_id']);
        }
      }

      final List<dynamic> allUsers = jsonDecode(usersResponse.body);
      print('All users: ${allUsers.length}');
      
      setState(() {
        candidates = allUsers
            .where((user) {
              final userId = user['id'] as String;
              // Filter out: current user, accepted connections, pending requests
              return userId != currentUserId &&
                  !acceptedConnectionIds.contains(userId) &&
                  !pendingUserIds.contains(userId);
            })
            .map((user) => {
              'id': user['id'] as String,
              'name': user['name'] as String,
              'email': user['email'] as String,
              'role': user['role'] as String,
              'phone_number': user['phone_number'] as String?,
              'skills': ['Flutter', 'Python', 'JavaScript'],
              'match': '${(75 + (user['id'].hashCode % 20)).clamp(0, 100)}%'
            })
            .toList();
        
        print('Filtered candidates: ${candidates.length}');
        isLoading = false;
      });
    } catch (e) {
      print('Error loading candidates: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _sendConnectionRequest(String candidateId) async {
    final result = await ConnectionService.sendConnectionRequest(candidateId);
    
    if (mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Remove candidate from list after sending request
        setState(() {
          candidates.removeWhere((c) => c['id'] == candidateId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent! 🎉'),
            backgroundColor: Color(0xFF7C8CF8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Candidates'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              _loadCandidates();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading candidates',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            hasError = false;
                          });
                          _loadCandidates();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : candidates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'All caught up! 🎉',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No new candidates available',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '(You\'ve connected or have pending requests with everyone)',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with gradient background
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primary,
                                      primary.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      child: Text(
                                        candidate['name'][0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            candidate['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            candidate['role'],
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        candidate['match'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Body content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Email and phone
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            candidate['email'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (candidate['phone_number'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            candidate['phone_number'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    // Skills section
                                    Text(
                                      'Skills',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (candidate['skills'] as List<String>)
                                          .map(
                                            (skill) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    primary.withOpacity(0.1),
                                                    primary.withOpacity(0.05),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: primary.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                skill,
                                                style: TextStyle(
                                                  color: primary,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              // Action buttons
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: BorderSide(
                                            color: primary.withOpacity(0.5),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: Text(
                                          'View Profile',
                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 4,
                                        ),
                                        onPressed: () => _sendConnectionRequest(candidate['id']),
                                        child: const Text(
                                          'Connect',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
