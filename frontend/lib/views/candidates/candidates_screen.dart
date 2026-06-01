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
  Color get primary => Theme.of(context).primaryColor;

  List<Map<String, dynamic>> candidates    = [];
  bool    isLoading     = true;
  bool    hasError      = false;
  String? currentUserId;

  // ── Local interactivity state ──────────────────────────────────────────────
  final Set<String> _favorites = {};   // saved candidate ids
  String _sortBy = 'default';          // default | name | match

  static const _sortOptions = {
    'default': 'Default',
    'name':    'Name (A→Z)',
    'match':   'Match % (High→Low)',
  };

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
        Uri.parse('http://192.168.1.28:8001/api/users/all'),
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
                  'matchValue':
                      (75 + (user['id'].hashCode % 20)).clamp(0, 100),
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

  // ── Favorite toggle ───────────────────────────────────────────────────────
  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:  Text('Removed from saved'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _favorites.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('Candidate saved ⭐'),
            backgroundColor: Colors.amber,
            duration:        Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // ── Dismiss (hide) candidate with undo ────────────────────────────────────
  void _dismissCandidate(Map<String, dynamic> candidate, int index) {
    setState(() => candidates.removeAt(index));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  Text('${candidate['name']} hidden'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label:     'Undo',
          textColor: Colors.yellow,
          onPressed: () => setState(() => candidates.insert(index, candidate)),
        ),
      ),
    );
  }

  // ── Sorted list ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _sorted {
    final list = List<Map<String, dynamic>>.from(candidates);
    switch (_sortBy) {
      case 'name':
        list.sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String));
      case 'match':
        list.sort((a, b) =>
            (b['matchValue'] as int).compareTo(a['matchValue'] as int));
    }
    // favorites always on top
    list.sort((a, b) {
      final aFav = _favorites.contains(a['id']) ? 0 : 1;
      final bFav = _favorites.contains(b['id']) ? 0 : 1;
      return aFav.compareTo(bFav);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile  = ResponsiveHelper.isMobile(context);
    final padding   = ResponsiveHelper.getResponsivePadding(context);
    final cardColor = Theme.of(context).cardColor;
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;
    final sorted    = _sorted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Candidates'),
        backgroundColor: primary,
        elevation:       0,
        foregroundColor: Colors.white,
        centerTitle:     isMobile,
        actions: [
          // ── Sort dropdown ─────────────────────────────────────────
          PopupMenuButton<String>(
            icon:        const Icon(Icons.sort, color: Colors.white),
            tooltip:     'Sort',
            onSelected:  (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => _sortOptions.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(children: [
                        if (_sortBy == e.key)
                          const Icon(Icons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(e.value),
                      ]),
                    ))
                .toList(),
          ),
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
                              color:    hintColor,
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
              : sorted.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: hintColor),
                          const SizedBox(height: 16),
                          Text('No candidates available',
                              style:
                                  TextStyle(color: hintColor, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:     padding,
                      itemCount:   sorted.length,
                      itemBuilder: (context, index) {
                        final candidate = sorted[index];
                        final isFav     =
                            _favorites.contains(candidate['id'] as String);
                        // real index in mutable list for undo
                        final realIndex = candidates.indexOf(candidate);

                        return Dismissible(
                          key:       ValueKey(candidate['id']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) =>
                              _dismissCandidate(candidate, realIndex),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:   const EdgeInsets.symmetric(
                                horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color:        Colors.grey[600],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 6),
                                Text('Hide',
                                    style: TextStyle(
                                        color:      Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color:        cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: isFav
                                  ? Border.all(
                                      color:  Colors.amber,
                                      width:  1.5)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.black
                                      .withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset:     const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Card header (gradient) ──────────────
                                Container(
                                  padding: const EdgeInsets.all(16),
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
                                        radius:          24,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.3),
                                        child: Text(
                                          (candidate['name'] as String)[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color:      Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize:   20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              candidate['name'],
                                              style: const TextStyle(
                                                color:      Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize:   16,
                                              ),
                                            ),
                                            Text(
                                              candidate['role'],
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ── Match % badge ─────────────
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
                                      const SizedBox(width: 8),
                                      // ── Favorite star ──────────────
                                      GestureDetector(
                                        onTap: () => _toggleFavorite(
                                            candidate['id'] as String),
                                        child: Icon(
                                          isFav
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: isFav
                                              ? Colors.amber
                                              : Colors.white
                                                  .withValues(alpha: 0.8),
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── Card body ───────────────────────────
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (candidate['phone_number'] !=
                                          null) ...[
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
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: primary
                                                          .withValues(
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

                                // ── Action buttons ──────────────────────
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding:
                                                const EdgeInsets.symmetric(
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
                                                  color: primary,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            padding:
                                                const EdgeInsets.symmetric(
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
                          ),
                        );
                      },
                    ),
    );
  }
}