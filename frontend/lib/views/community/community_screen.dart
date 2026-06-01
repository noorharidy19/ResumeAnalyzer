import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/connection_service.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/app_providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  // getter — always reads from live theme
  Color get primary => Theme.of(context).primaryColor;

  List<Map<String, dynamic>> pendingRequests = [];
  bool    isLoading     = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = ref.read(authProvider).userId;
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => isLoading = true);
    final result = await ConnectionService.getPendingRequests();
    setState(() {
      if (result.containsKey('requests')) {
        final all = List<Map<String, dynamic>>.from(result['requests'] ?? []);
        if (currentUserId != null && currentUserId!.isNotEmpty) {
          pendingRequests = all.where((r) {
            return r['receiver_id']?.toString() == currentUserId;
          }).toList();
        } else {
          pendingRequests = all;
        }
      }
      isLoading = false;
    });
  }

  void _acceptRequest(String connectionId, int index) async {
    final result = await ConnectionService.acceptConnection(connectionId);
    if (mounted) {
      if (result.containsKey('message')) {
        setState(() => pendingRequests.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('Connection accepted! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Error: ${result['error'] ?? 'Failed to accept'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectRequest(String connectionId, int index) async {
    final result = await ConnectionService.rejectConnection(connectionId);
    if (mounted) {
      if (result.containsKey('message')) {
        setState(() => pendingRequests.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('Connection rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Error: ${result['error'] ?? 'Failed to reject'}'),
            backgroundColor: Colors.red,
          ),
        );
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
        title:           const Text('Community'),
        backgroundColor: primary,
        elevation:       0,
        foregroundColor: Colors.white,
        centerTitle:     isMobile,
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPendingRequests,
              color:     primary,
              child:     pendingRequests.isEmpty
                  ? ListView(
                      padding:  padding,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: isMobile ? 48 : 64, color: hintColor),
                            const SizedBox(height: 16),
                            Text('No pending requests',
                                style: TextStyle(color: hintColor, fontSize: isMobile ? 14 : 16)),
                            const SizedBox(height: 8),
                            Text('Pull down to refresh',
                                style: TextStyle(color: hintColor?.withValues(alpha: 0.6), fontSize: 12)),
                          ],
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:     padding,
                      itemCount:   pendingRequests.length,
                      itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    final sender  = request['sender'] ?? {};

                    return Container(
                      margin: EdgeInsets.only(
                          bottom: isMobile ? 8 : 12),
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color:        cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius:          isMobile ? 18 : 24,
                                backgroundColor: primary.withValues(alpha: 0.2),
                                child: Text(
                                  (sender['name'] ?? 'U')[0],
                                  style: TextStyle(
                                    color:      primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize:   isMobile ? 12 : 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: isMobile ? 8 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sender['name'] ?? 'Unknown User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:   isMobile ? 14 : 16,
                                      ),
                                    ),
                                    Text(
                                      sender['email'] ?? '',
                                      style: TextStyle(
                                        color:    hintColor,
                                        fontSize: isMobile ? 11 : 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          Text(
                            'wants to connect with you',
                            style: TextStyle(
                                color:    hintColor,
                                fontSize: isMobile ? 12 : 14),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: primary.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      _rejectRequest(request['id'], index),
                                  child: Text('Decline',
                                      style: TextStyle(color: primary)),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      _acceptRequest(request['id'], index),
                                  child: const Text('Accept',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: primary.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      _rejectRequest(request['id'], index),
                                  child: Text('Decline',
                                      style: TextStyle(color: primary)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      _acceptRequest(request['id'], index),
                                  child: const Text('Accept',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                      },
                    ),
            ),
    );
  }
}