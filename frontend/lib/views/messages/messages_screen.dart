import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/connection_service.dart';
import '../../services/message_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with TickerProviderStateMixin {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg = const Color(0xFFF5F7FF);
  
  List<Map<String, dynamic>> acceptedConnections = [];
  List<Map<String, dynamic>> sentRequests = [];
  List<Map<String, dynamic>> receivedRequests = [];
  Map<String, int> unreadCounts = {}; // Store unread count for each connection
  bool isLoading = true;
  String? currentUserId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
          setState(() {
            currentUserId = decoded['sub'];
          });
        }
      } catch (e) {
        print('Error decoding token: $e');
      }
    }
    
    _loadAllConnections();
  }

  Future<void> _loadAllConnections() async {
    try {
      final acceptedResult = await ConnectionService.getMyConnections();
      final pendingResult = await ConnectionService.getPendingRequests();
      
      if (mounted) {
        setState(() {
          // Accepted connections
          acceptedConnections = List<Map<String, dynamic>>.from(acceptedResult ?? []);
          
          // Load unread count for each connection (without marking as read)
          for (var connection in acceptedConnections) {
            _loadUnreadCountForConnection(connection['id']);
          }
          
          // Separate pending requests into sent and received
          final allRequests = List<Map<String, dynamic>>.from(
            (pendingResult is Map && pendingResult.containsKey('requests'))
                ? pendingResult['requests'] ?? []
                : []
          );
          
          sentRequests = [];
          receivedRequests = [];
          
          for (var req in allRequests) {
            if (req['sender_id'] == currentUserId) {
              sentRequests.add(req);
            } else if (req['receiver_id'] == currentUserId) {
              receivedRequests.add(req);
            }
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading connections: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCountForConnection(String connectionId) async {
    final result = await MessageService.getUnreadCountForConnection(connectionId);
    if (!result.containsKey('error')) {
      final unreadCount = result['unread_count'] ?? 0;
      if (mounted) {
        setState(() {
          unreadCounts[connectionId] = unreadCount;
        });
      }
    }
  }

  Map<String, dynamic>? _getOtherUser(Map<String, dynamic> connection) {
    if (currentUserId == null) return null;
    
    final senderId = connection['sender_id'];
    final receiverId = connection['receiver_id'];
    
    if (senderId == currentUserId) {
      return connection['receiver'];
    } else {
      return connection['sender'];
    }
  }

  void _openChat(Map<String, dynamic> connection) {
    final otherUser = _getOtherUser(connection);
    
    if (otherUser == null) return;

    final TextEditingController messageController = TextEditingController();
    String? connectionId = connection['id'];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: MessageService.getChatHistory(connectionId ?? ''),
            builder: (context, snapshot) {
              List<Message> messages = [];
              int unreadCount = 0;
              if (snapshot.hasData && !snapshot.data!.containsKey('error')) {
                messages = snapshot.data!['messages'] ?? [];
                unreadCount = snapshot.data!['unread_count'] ?? 0;
                
                // Mark the last unreadCount messages as unread
                for (int i = messages.length - unreadCount; i < messages.length; i++) {
                  if (i >= 0 && i < messages.length) {
                    messages[i].isRead = false; // Mark for bold display
                  }
                }
                
                // Don't reset badge here - let it persist until user reads messages
                // Badge will be updated when chat history is reloaded
              }

              return Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: Text(
                                (otherUser['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherUser['name'] ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.green[300],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Active now',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      // Chat area
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading messages...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 48,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No messages yet',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Start the conversation!',
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
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[index];
                                      final isCurrentUserMessage =
                                          message.senderId == currentUserId;

                                      return Align(
                                        alignment: isCurrentUserMessage
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          constraints: BoxConstraints(
                                            maxWidth: MediaQuery.of(context).size.width * 0.65,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCurrentUserMessage
                                                ? null
                                                : Colors.grey[200],
                                            gradient: isCurrentUserMessage
                                                ? LinearGradient(
                                                    colors: [
                                                      primary,
                                                      primary.withOpacity(0.8)
                                                    ],
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                isCurrentUserMessage
                                                    ? CrossAxisAlignment.end
                                                    : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message.content,
                                                style: TextStyle(
                                                  color: isCurrentUserMessage
                                                      ? Colors.white
                                                      : Colors.grey[800],
                                                  fontSize: 15,
                                                  fontWeight: message.isRead
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatMessageTime(message.createdAt),
                                                style: TextStyle(
                                                  color: isCurrentUserMessage
                                                      ? Colors.white.withOpacity(0.75)
                                                      : Colors.grey[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      // Input area
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: primary),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary, primary.withOpacity(0.8)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: () async {
                                  if (messageController.text.isNotEmpty &&
                                      connectionId != null) {
                                    final content = messageController.text;
                                    messageController.clear();

                                    final result =
                                        await MessageService.sendMessage(
                                      connectionId,
                                      content,
                                    );

                                    if (!result.containsKey('error')) {
                                      // Create a Message object from the response
                                      final newMessage = Message(
                                        id: result['id'],
                                        senderId: result['sender_id'],
                                        receiverId: result['receiver_id'],
                                        content: result['content'],
                                        isRead: result['is_read'],
                                        createdAt: DateTime.parse(
                                            result['created_at']),
                                        sender: result['sender'],
                                        receiver: result['receiver'],
                                      );

                                      setDialogState(() {
                                        // Reload messages
                                      });

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Message sent! ✓'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(milliseconds: 800),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error: ${result['error']}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
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
          );
        },
      ),
    ).then((_) {
      // After chat is closed, reset the unread count since messages are marked as read
      if (mounted) {
        setState(() {
          unreadCounts[connectionId ?? ''] = 0;
        });
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    // Ensure we're working with UTC
    final messageTimeUtc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    
    // Get current time in UTC
    final nowUtc = DateTime.now().toUtc();
    
    // Calculate difference
    final difference = nowUtc.difference(messageTimeUtc);
    
    // Convert to Cairo time (UTC+2) for display only
    final cairoTime = messageTimeUtc.add(const Duration(hours: 2));

    if (difference.inSeconds < 0) {
      return 'now';
    } else if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins == 1 ? '1m ago' : '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1h ago' : '${hours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${cairoTime.hour.toString().padLeft(2, '0')}:${cairoTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days days ago';
    } else {
      return '${cairoTime.day}/${cairoTime.month} ${cairoTime.hour.toString().padLeft(2, '0')}:${cairoTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _acceptRequest(int index) async {
    final request = receivedRequests[index];
    final result = await ConnectionService.acceptConnection(request['id']);
    
    if (mounted) {
      if (result.containsKey('message')) {
        setState(() {
          receivedRequests.removeAt(index);
          acceptedConnections.add(request);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection accepted! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _rejectRequest(int index) async {
    final request = receivedRequests[index];
    final result = await ConnectionService.rejectConnection(request['id']);
    
    if (mounted) {
      if (result.containsKey('message')) {
        setState(() {
          receivedRequests.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildConnectionCard(Map<String, dynamic> connection, {bool canMessage = false, bool showActions = false, VoidCallback? onAccept, VoidCallback? onReject}) {
    final otherUser = _getOtherUser(connection);
    
    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canMessage ? () => _openChat(connection) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: primary.withOpacity(0.15),
                      child: Text(
                        (otherUser['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    // Online indicator
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green[400],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        otherUser['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canMessage)
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withOpacity(0.7)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      (unreadCounts[connection['id']] ?? 0).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (showActions)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.check,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          onPressed: onAccept,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.red[600],
                            size: 20,
                          ),
                          onPressed: onReject,
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Connections'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: TabBar(
            controller: _tabController,
            labelColor: primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: primary,
            indicatorWeight: 3,
            tabs: [
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(height: 2),
                    Text(
                      'Accepted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_up_outlined),
                    const SizedBox(height: 2),
                    Text(
                      'Sent',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_down_outlined),
                    const SizedBox(height: 2),
                    Text(
                      'Received',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Accepted Connections
                acceptedConnections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No accepted connections',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accept requests to start messaging',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: acceptedConnections.length,
                        itemBuilder: (context, index) {
                          return _buildConnectionCard(
                            acceptedConnections[index],
                            canMessage: true,
                          );
                        },
                      ),
                
                // Sent Requests
                sentRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sent requests',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sentRequests.length,
                        itemBuilder: (context, index) {
                          return _buildConnectionCard(
                            sentRequests[index],
                          );
                        },
                      ),
                
                // Received Requests
                receivedRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mail,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending requests',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: receivedRequests.length,
                        itemBuilder: (context, index) {
                          return _buildConnectionCard(
                            receivedRequests[index],
                            showActions: true,
                            onAccept: () => _acceptRequest(index),
                            onReject: () => _rejectRequest(index),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
