import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/connection_service.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/app_providers.dart';

class CandidatesScreen extends ConsumerStatefulWidget {
  const CandidatesScreen({super.key});

  @override
  ConsumerState<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends ConsumerState<CandidatesScreen> {
  // primary is a getter so it always reads from the current theme
  Color get primary => Theme.of(context).primaryColor;

  List<Map<String, dynamic>> candidates = [];
  bool    isLoading     = true;
  bool    hasError      = false;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    try {
      final auth  = ref.read(authProvider);
      final token = auth.token;

      if (token == null) {
        setState(() { hasError = true; isLoading = false; });
        return;
      }

      currentUserId = auth.userId;

      final usersResponse = await http.get(
        Uri.parse('http://localhost:8001/api/users/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (usersResponse.statusCode != 200) {
        setState(() { hasError = true; isLoading = false; });
        return;
      }

      final acceptedResult        = await ConnectionService.getMyConnections();
      final acceptedConnectionIds = <String>{};
      if (acceptedResult is List) {
        for (var conn in acceptedResult) {
          acceptedConnectionIds.add(conn['sender_id']);
          acceptedConnectionIds.add(conn['receiver_id']);
        }
      }

      final pendingResult  = await ConnectionService.getPendingRequests();
      final pendingUserIds = <String>{};
      if (pendingResult is Map && pendingResult.containsKey('requests')) {
        for (var req in (pendingResult['requests'] ?? [])) {
          pendingUserIds.add(req['sender_id']);
          pendingUserIds.add(req['receiver_id']);
        }
      }

      if (!mounted) return;

      final List<dynamic> allUsers = jsonDecode(usersResponse.body);

      setState(() {
        candidates = allUsers
            .where((user) {
              final userId = user['id'] as String;
              return userId != currentUserId &&
                  !acceptedConnectionIds.contains(userId) &&
                  !pendingUserIds.contains(userId);
            })
            .map((user) => {
                  'id':           user['id']           as String,
                  'name':         user['name']         as String,
                  'email':        user['email']        as String,
                  'role':         user['role']         as String,
                  'phone_number': user['phone_number'] as String?,
                  'skills':       ['Flutter', 'Python', 'JavaScript'],
                  'match':
                      '${(75 + (user['id'].hashCode % 20)).clamp(0, 100)}%',
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading candidates: $e');
      if (mounted) setState(() { hasError = true; isLoading = false; });
    }
  }

  void _sendConnectionRequest(String candidateId) async {
    final result = await ConnectionService.sendConnectionRequest(candidateId);

    if (mounted) {
      if (result.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('${result['error']}'),
          backgroundColor: Colors.red,
        ));
      } else {
        setState(() =>
            candidates.removeWhere((c) => c['id'] == candidateId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         const Text('Connection request sent! 🎉'),
          backgroundColor: Theme.of(context).primaryColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile  = ResponsiveHelper.isMobile(context);
    final padding   = ResponsiveHelper.getResponsivePadding(context);
    final cardColor = Theme.of(context).cardColor;
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Candidates'),
        backgroundColor: primary,
        elevation:       0,
        foregroundColor: Colors.white,
        centerTitle:     isMobile,
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: () {
              setState(() { isLoading = true; hasError = false; });
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
                      Icon(Icons.error,
                          size:  isMobile ? 48 : 64,
                          color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error loading candidates',
                          style: TextStyle(
                              color: hintColor,
                              fontSize: isMobile ? 14 : 16)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { isLoading = true; hasError = false; });
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
                          Icon(Icons.check_circle,
                              size:  isMobile ? 48 : 64,
                              color: Colors.green[300]),
                          const SizedBox(height: 16),
                          Text('All caught up! 🎉',
                              style: TextStyle(
                                  color:      hintColor,
                                  fontSize:   isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('No new candidates available',
                              style: TextStyle(
                                  color:    hintColor,
                                  fontSize: isMobile ? 12 : 14)),
                          const SizedBox(height: 16),
                          Text(
                            "(You've connected or have pending requests with everyone)",
                            style: TextStyle(
                                color:    hintColor,
                                fontSize: isMobile ? 10 : 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:     padding,
                      itemCount:   candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        return Container(
                          margin: EdgeInsets.only(
                              bottom: isMobile ? 12 : 16),
                          decoration: BoxDecoration(
                            color:        cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:      primary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset:     const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Gradient header (intentional branding — keep as-is) ──
                              Container(
                                padding: EdgeInsets.all(isMobile ? 12 : 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primary,
                                      primary.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end:   Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft:  Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius:          28,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.3),
                                      child: Text(
                                        candidate['name'][0].toUpperCase(),
                                        style: const TextStyle(
                                          color:      Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize:   24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(candidate['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:   18,
                                                color:      Colors.white,
                                              )),
                                          const SizedBox(height: 4),
                                          Text(candidate['role'],
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                fontSize: 14,
                                              )),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(candidate['match'],
                                          style: const TextStyle(
                                            color:      Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize:   12,
                                          )),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Card body ──────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Icon(Icons.email_outlined,
                                          size: 16, color: hintColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(candidate['email'],
                                            style: TextStyle(
                                                color:    hintColor,
                                                fontSize: 13)),
                                      ),
                                    ]),
                                    if (candidate['phone_number'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        Icon(Icons.phone_outlined,
                                            size: 16, color: hintColor),
                                        const SizedBox(width: 8),
                                        Text(candidate['phone_number'],
                                            style: TextStyle(
                                                color:    hintColor,
                                                fontSize: 13)),
                                      ]),
                                    ],
                                    const SizedBox(height: 12),
                                    Text('Skills',
                                        style: TextStyle(
                                            color:      hintColor,
                                            fontSize:   12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing:    8,
                                      runSpacing: 8,
                                      children: (candidate['skills']
                                              as List<String>)
                                          .map((skill) => Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 12,
                                                    vertical:   6),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      primary.withValues(
                                                          alpha: 0.15),
                                                      primary.withValues(
                                                          alpha: 0.08),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: primary.withValues(
                                                        alpha: 0.3),
                                                  ),
                                                ),
                                                child: Text(skill,
                                                    style: TextStyle(
                                                      color:      primary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 12,
                                                    )),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Action buttons ─────────────────────────────
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          side: BorderSide(
                                            color: primary.withValues(
                                                alpha: 0.5),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: Text('View Profile',
                                            style: TextStyle(
                                                color:      primary,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          elevation: 4,
                                        ),
                                        onPressed: () =>
                                            _sendConnectionRequest(
                                                candidate['id']),
                                        child: const Text('Connect',
                                            style: TextStyle(
                                              color:      Colors.white,
                                              fontWeight: FontWeight.bold,
                                            )),
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