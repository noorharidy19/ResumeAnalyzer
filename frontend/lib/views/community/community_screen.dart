import 'package:flutter/material.dart';
import '../../services/connection_service.dart';
import '../../utils/responsive_helper.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg = const Color(0xFFF5F7FF);
  
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    final result = await ConnectionService.getPendingRequests();
    
    setState(() {
      if (result.containsKey('requests')) {
        pendingRequests = List<Map<String, dynamic>>.from(result['requests'] ?? []);
      }
      isLoading = false;
    });
  }

  void _acceptRequest(String connectionId, int index) async {
    final result = await ConnectionService.acceptConnection(connectionId);
    
    if (mounted) {
      if (result.containsKey('message')) {
        setState(() {
          pendingRequests.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection accepted! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error'] ?? 'Failed to accept'}'),
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
        setState(() {
          pendingRequests.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error'] ?? 'Failed to reject'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: primary,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: isMobile,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: isMobile ? 48 : 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: padding,
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    final sender = request['sender'] ?? {};

                    return Container(
                      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
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
                                radius: isMobile ? 18 : 24,
                                backgroundColor: primary.withOpacity(0.2),
                                child: Text(
                                  (sender['name'] ?? 'U')[0],
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 12 : 14,
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
                                        fontSize: isMobile ? 14 : 16,
                                      ),
                                    ),
                                    Text(
                                      sender['email'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
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
                              color: Colors.grey[600],
                              fontSize: isMobile ? 12 : 14,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _rejectRequest(request['id'], index),
                                  child: const Text('Decline'),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                  ),
                                  onPressed: () =>
                                      _acceptRequest(request['id'], index),
                                  child: const Text(
                                    'Accept',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                    );
                  },
                ),
    );
  }
}
