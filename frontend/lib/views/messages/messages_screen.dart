import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../services/connection_service.dart';
import '../../services/message_service.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/app_providers.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with TickerProviderStateMixin {
  Color get primary   => Theme.of(context).primaryColor;
  Color get cardColor => Theme.of(context).cardColor;

  List<Map<String, dynamic>> acceptedConnections = [];
  List<Map<String, dynamic>> sentRequests        = [];
  List<Map<String, dynamic>> receivedRequests    = [];
  Map<String, int> unreadCounts = {};
  bool    isLoading     = true;
  String? currentUserId;
  late TabController _tabController;

  // ── Local interactivity state ──────────────────────────────────────────────
  final Set<String> _pinned = {};   // pinned connection ids
  String _sortBy = 'default';       // default | name | unread

  static const _sortOptions = {
    'default': 'Default',
    'name':    'Name (A→Z)',
    'unread':  'Unread First',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUserId  = ref.read(authProvider).userId;
    _loadAllConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllConnections() async {
    try {
      final acceptedResult = await ConnectionService.getMyConnections();
      final pendingResult  = await ConnectionService.getPendingRequests();

      if (mounted) {
        setState(() {
          acceptedConnections =
              List<Map<String, dynamic>>.from(acceptedResult ?? []);

          for (var connection in acceptedConnections) {
            _loadUnreadCountForConnection(connection['id']);
          }

          final allRequests = List<Map<String, dynamic>>.from(
            (pendingResult is Map &&
                    pendingResult.containsKey('requests'))
                ? pendingResult['requests'] ?? []
                : [],
          );

          sentRequests     = [];
          receivedRequests = [];

          for (var req in allRequests) {
            final sid = req['sender_id']?.toString()   ?? '';
            final rid = req['receiver_id']?.toString() ?? '';
            final mid = currentUserId?.toString()       ?? '';
            if (mid.isNotEmpty && sid == mid) {
              sentRequests.add(req);
            } else if (mid.isNotEmpty && rid == mid) {
              receivedRequests.add(req);
            }
          }

          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadUnreadCountForConnection(String connectionId) async {
    final result =
        await MessageService.getUnreadCountForConnection(connectionId);
    if (!result.containsKey('error') && mounted) {
      setState(() {
        unreadCounts[connectionId] = result['unread_count'] ?? 0;
      });
    }
  }

  Map<String, dynamic>? _getOtherUser(Map<String, dynamic> connection) {
    if (currentUserId == null) return null;
    final isSender = connection['sender_id']?.toString() == currentUserId!.toString();
    final raw = isSender ? connection['receiver'] : connection['sender'];
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  // ── Pin (favorite) toggle ─────────────────────────────────────────────────
  void _togglePin(String connectionId) {
    setState(() {
      if (_pinned.contains(connectionId)) {
        _pinned.remove(connectionId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:  Text('Conversation unpinned'),
          duration: Duration(seconds: 2),
        ));
      } else {
        _pinned.add(connectionId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('Conversation pinned 📌'),
          backgroundColor: Colors.indigo,
          duration:        Duration(seconds: 2),
        ));
      }
    });
  }

  // ── Delete (hide) connection with undo ────────────────────────────────────
  void _hideConnection(Map<String, dynamic> connection, int index) {
    final otherUser = _getOtherUser(connection);
    setState(() => acceptedConnections.removeAt(index));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  Text('${otherUser?['name'] ?? 'Connection'} hidden'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label:     'Undo',
          textColor: Colors.yellow,
          onPressed: () =>
              setState(() => acceptedConnections.insert(index, connection)),
        ),
      ),
    );
  }

  // ── Sorted accepted connections ───────────────────────────────────────────
  List<Map<String, dynamic>> get _sortedAccepted {
    final list = List<Map<String, dynamic>>.from(acceptedConnections);

    switch (_sortBy) {
      case 'name':
        list.sort((a, b) {
          final aUser = _getOtherUser(a);
          final bUser = _getOtherUser(b);
          return (aUser?['name'] ?? '').compareTo(bUser?['name'] ?? '');
        });
      case 'unread':
        list.sort((a, b) {
          final aUnread = unreadCounts[a['id']] ?? 0;
          final bUnread = unreadCounts[b['id']] ?? 0;
          return bUnread.compareTo(aUnread);
        });
    }

    // pinned always on top
    list.sort((a, b) {
      final aPinned = _pinned.contains(a['id']) ? 0 : 1;
      final bPinned = _pinned.contains(b['id']) ? 0 : 1;
      return aPinned.compareTo(bPinned);
    });

    return list;
  }

  void _openChat(Map<String, dynamic> connection) {
    final otherUser    = _getOtherUser(connection);
    if (otherUser == null) return;

    final TextEditingController messageController = TextEditingController();
    String? connectionId = connection['id'];

    final dialogCardColor = cardColor;
    final dialogPrimary   = primary;
    final hintColor       = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor    = Theme.of(context).dividerColor;
    final receivedBubble  = Theme.of(context).colorScheme.surface;
    final receivedText    = Theme.of(context).textTheme.bodyMedium?.color;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return FutureBuilder<Map<String, dynamic>>(
            future: MessageService.getChatHistory(connectionId ?? ''),
            builder: (dialogContext, snapshot) {
              List<Message> messages    = [];
              int           unreadCount = 0;

              if (snapshot.hasData && !snapshot.data!.containsKey('error')) {
                messages    = snapshot.data!['messages']     ?? [];
                unreadCount = snapshot.data!['unread_count'] ?? 0;

                for (int i = messages.length - unreadCount;
                    i < messages.length;
                    i++) {
                  if (i >= 0 && i < messages.length) {
                    messages[i].isRead = false;
                  }
                }
              }

              return Dialog(
                insetPadding:    const EdgeInsets.all(16),
                backgroundColor: dialogCardColor,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color:        dialogCardColor,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                    maxWidth:  MediaQuery.of(dialogContext).size.width  * 0.9,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Chat header ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              dialogPrimary,
                              dialogPrimary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end:   Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft:  Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius:          24,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              child: Text(
                                (otherUser['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  color:      Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:   18,
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
                                      color:      Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize:   16,
                                    ),
                                  ),
                                  Row(children: [
                                    Container(
                                      width:  8,
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
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize:   12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                              onPressed: () =>
                                  Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                      ),

                      // ── Chat area ────────────────────────────────────
                      Expanded(
                        child: snapshot.connectionState ==
                                ConnectionState.waiting
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          dialogPrimary),
                                ))
                            : messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_bubble_outline,
                                            size:  48,
                                            color: hintColor),
                                        const SizedBox(height: 12),
                                        Text('No messages yet',
                                            style: TextStyle(
                                                color:    hintColor,
                                                fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('Start the conversation!',
                                            style: TextStyle(
                                                color:    hintColor,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding:   const EdgeInsets.all(16),
                                    itemCount: messages.length,
                                    itemBuilder: (dialogContext, index) {
                                      final message = messages[index];
                                      final isMe =
                                          message.senderId == currentUserId;
                                      return Align(
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 12),
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(dialogContext)
                                                        .size
                                                        .width *
                                                    0.65,
                                          ),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical:   10),
                                          decoration: BoxDecoration(
                                            color: isMe ? null : receivedBubble,
                                            gradient: isMe
                                                ? LinearGradient(colors: [
                                                    dialogPrimary,
                                                    dialogPrimary.withValues(
                                                        alpha: 0.8),
                                                  ])
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message.content,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : receivedText,
                                                  fontSize:   15,
                                                  fontWeight: message.isRead
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatMessageTime(
                                                    message.createdAt),
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                          .withValues(
                                                              alpha: 0.75)
                                                      : hintColor,
                                                  fontSize:   12,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),

                      // ── Input area ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: dividerColor)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  hintText:  'Type a message...',
                                  hintStyle: TextStyle(color: hintColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide:
                                        BorderSide(color: dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(
                                        color: dialogPrimary),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                ),
                                maxLines: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  dialogPrimary,
                                  dialogPrimary.withValues(alpha: 0.8),
                                ]),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.white),
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
                                      final newMessage = Message(
                                        id:         result['id'],
                                        senderId:   result['sender_id'],
                                        receiverId: result['receiver_id'],
                                        content:    result['content'],
                                        isRead:     result['is_read'],
                                        createdAt:  DateTime.parse(
                                            result['created_at']),
                                        sender:   result['sender'],
                                        receiver: result['receiver'],
                                      );
                                      setDialogState(() {});
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text('Message sent! ✓'),
                                          backgroundColor: Colors.green,
                                          duration:
                                              Duration(milliseconds: 800),
                                        ));
                                      }
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Error: ${result['error']}'),
                                        backgroundColor: Colors.red,
                                      ));
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
      if (mounted) {
        setState(() => unreadCounts[connectionId ?? ''] = 0);
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    final messageTimeUtc =
        dateTime.isUtc ? dateTime : dateTime.toUtc();
    final nowUtc     = DateTime.now().toUtc();
    final difference = nowUtc.difference(messageTimeUtc);
    final cairoTime  = messageTimeUtc.add(const Duration(hours: 2));

    if (difference.inSeconds < 60)  return 'now';
    if (difference.inMinutes < 60)  return '${difference.inMinutes}m ago';
    if (difference.inHours   < 24)  return '${difference.inHours}h ago';
    if (difference.inDays    == 1) {
      return 'Yesterday '
          '${cairoTime.hour.toString().padLeft(2, '0')}:'
          '${cairoTime.minute.toString().padLeft(2, '0')}';
    }
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${cairoTime.day}/${cairoTime.month} '
        '${cairoTime.hour.toString().padLeft(2, '0')}:'
        '${cairoTime.minute.toString().padLeft(2, '0')}';
  }

  void _acceptRequest(int index) async {
    final request = receivedRequests[index];
    final result  = await ConnectionService.acceptConnection(request['id']);
    if (mounted && result.containsKey('message')) {
      setState(() {
        receivedRequests.removeAt(index);
        acceptedConnections.add(request);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Connection accepted! 🎉'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _rejectRequest(int index) async {
    final request = receivedRequests[index];
    final result  = await ConnectionService.rejectConnection(request['id']);
    if (mounted && result.containsKey('message')) {
      setState(() => receivedRequests.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Connection rejected'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  // ── Connection card (shared across all 3 tabs) ────────────────────────────
  Widget _buildConnectionCard(
    Map<String, dynamic> connection, {
    bool          canMessage  = false,
    bool          showActions = false,
    VoidCallback? onAccept,
    VoidCallback? onReject,
    int?          listIndex,   // needed for undo
  }) {
    final otherUser = _getOtherUser(connection);
    if (otherUser == null) return const SizedBox.shrink();

    final hintColor  = Theme.of(context).textTheme.bodySmall?.color;
    final connId     = connection['id'] as String;
    final isPinned   = _pinned.contains(connId);
    final unread     = unreadCounts[connId] ?? 0;

    // Only accepted tab gets dismiss + pin
    if (canMessage) {
      return Dismissible(
        key:       ValueKey(connId),
        direction: DismissDirection.endToStart,
        onDismissed: (_) =>
            _hideConnection(connection, listIndex ?? 0),
        background: Container(
          alignment: Alignment.centerRight,
          padding:   const EdgeInsets.symmetric(horizontal: 20),
          margin:    const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color:        Colors.grey[700],
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_off, color: Colors.white, size: 22),
              SizedBox(width: 6),
              Text('Hide',
                  style: TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        child: _connectionCardBody(
          connection:  connection,
          otherUser:   otherUser,
          hintColor:   hintColor,
          connId:      connId,
          isPinned:    isPinned,
          unread:      unread,
          canMessage:  true,
        ),
      );
    }

    return _connectionCardBody(
      connection:  connection,
      otherUser:   otherUser,
      hintColor:   hintColor,
      connId:      connId,
      isPinned:    false,
      unread:      0,
      canMessage:  false,
      showActions: showActions,
      onAccept:    onAccept,
      onReject:    onReject,
    );
  }

  Widget _connectionCardBody({
    required Map<String, dynamic>  connection,
    required Map<String, dynamic>? otherUser,
    required Color?                hintColor,
    required String                connId,
    required bool                  isPinned,
    required int                   unread,
    required bool                  canMessage,
    bool                           showActions = false,
    VoidCallback?                  onAccept,
    VoidCallback?                  onReject,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isPinned
            ? Border.all(color: Colors.indigo, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color:      primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset:     const Offset(0, 2),
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
                      radius:          28,
                      backgroundColor: primary.withValues(alpha: 0.15),
                      child: Text(
                        (otherUser?['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color:      primary,
                          fontWeight: FontWeight.bold,
                          fontSize:   18,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right:  0,
                      child: Container(
                        width:  12,
                        height: 12,
                        decoration: BoxDecoration(
                          color:  Colors.green[400],
                          shape:  BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
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
                      Row(
                        children: [
                          if (isPinned) ...[
                            const Icon(Icons.push_pin,
                                size: 13, color: Colors.indigo),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              otherUser?['name'] ?? 'Unknown User',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        otherUser?['email'] ?? '',
                        style: TextStyle(color: hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (canMessage) ...[
                  // Pin button
                  GestureDetector(
                    onTap: () => _togglePin(connId),
                    child: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isPinned ? Colors.indigo : hintColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unread badge
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        primary,
                        primary.withValues(alpha: 0.7),
                      ]),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else if (showActions)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.check,
                              color: Colors.green[600], size: 20),
                          onPressed:   onAccept,
                          iconSize:    20,
                          padding:     EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 40, minHeight: 40),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close,
                              color: Colors.red[600], size: 20),
                          onPressed:   onReject,
                          iconSize:    20,
                          padding:     EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(Icons.chevron_right, color: hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile  = ResponsiveHelper.isMobile(context);
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;
    final sorted    = _sortedAccepted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Connections'),
        backgroundColor: primary,
        elevation:       0,
        foregroundColor: Colors.white,
        centerTitle:     isMobile,
        actions: [
          // ── Sort dropdown (only meaningful for accepted tab) ───────
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: TabBar(
            controller:           _tabController,
            labelColor:           Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor:       Colors.white,
            indicatorWeight:      3,
            tabs: [
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(height: 2),
                    Text('Accepted',
                        style: TextStyle(
                            fontSize:   isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_up_outlined, size: 20),
                    const SizedBox(height: 2),
                    Text('Sent',
                        style: TextStyle(
                            fontSize:   isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_circle_down_outlined, size: 20),
                    const SizedBox(height: 2),
                    Text('Received',
                        style: TextStyle(
                            fontSize:   isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600)),
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
                // ── Accepted tab ──────────────────────────────────────
                sorted.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, size: 64, color: hintColor),
                            const SizedBox(height: 16),
                            Text('No accepted connections',
                                style: TextStyle(
                                    color: hintColor, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Accept requests to start messaging',
                                style: TextStyle(
                                    color: hintColor, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:     const EdgeInsets.all(16),
                        itemCount:   sorted.length,
                        itemBuilder: (context, index) =>
                            _buildConnectionCard(
                              sorted[index],
                              canMessage: true,
                              listIndex:  index,
                            ),
                      ),

                // ── Sent tab ──────────────────────────────────────────
                sentRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 64, color: hintColor),
                            const SizedBox(height: 16),
                            Text('No sent requests',
                                style: TextStyle(
                                    color: hintColor, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:     const EdgeInsets.all(16),
                        itemCount:   sentRequests.length,
                        itemBuilder: (context, index) =>
                            _buildConnectionCard(sentRequests[index]),
                      ),

                // ── Received tab ──────────────────────────────────────
                receivedRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mail, size: 64, color: hintColor),
                            const SizedBox(height: 16),
                            Text('No pending requests',
                                style: TextStyle(
                                    color: hintColor, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:     const EdgeInsets.all(16),
                        itemCount:   receivedRequests.length,
                        itemBuilder: (context, index) =>
                            _buildConnectionCard(
                              receivedRequests[index],
                              showActions: true,
                              onAccept: () => _acceptRequest(index),
                              onReject: () => _rejectRequest(index),
                            ),
                      ),
              ],
            ),
    );
  }
}