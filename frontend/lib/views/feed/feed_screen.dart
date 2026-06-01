import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../utils/responsive_helper.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // primary is a getter so it always reads from the current theme
  Color get primary => Theme.of(context).primaryColor;

  List<Post> posts      = [];
  bool isLoading        = true;
  int  totalCount       = 0;
  int  offset           = 0;
  final int limit       = 20;
  final TextEditingController postController = TextEditingController();
  int selectedTab       = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => isLoading = true);

    final result = selectedTab == 0
        ? await PostService.getFeed(limit: limit, offset: offset)
        : await PostService.getMyPosts(limit: limit, offset: offset);

    if (mounted) {
      setState(() => isLoading = false);

      if (result.containsKey('error')) {
        final err = result['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error loading ${selectedTab == 0 ? "feed" : "posts"}: $err'),
            backgroundColor: Colors.red,
          ),
        );
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title:   const Text('Feed error'),
              content: SingleChildScrollView(child: Text(err.toString())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close')),
              ],
            ),
          );
        }
      } else {
        setState(() {
          posts      = result['posts']       ?? [];
          totalCount = result['total_count'] ?? 0;
        });
      }
    }
  }

  Future<void> _createPost() async {
    if (postController.text.isEmpty) return;
    final content = postController.text;
    postController.clear();

    final result = await PostService.createPost(content);

    if (!result.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('Post created! ✓'),
            backgroundColor: Colors.green,
            duration:        Duration(milliseconds: 800),
          ),
        );
      }
      setState(() { selectedTab = 1; offset = 0; });
      _loadFeed();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _likePost(String postId) async {
    final result = await PostService.likePost(postId);
    if (!result.containsKey('error')) {
      _loadFeed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('✓ Like updated'),
            backgroundColor: Colors.green,
            duration:        Duration(milliseconds: 1000),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('❌ Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration:        const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _repostPost(String postId) async {
    final result = await PostService.repost(postId);
    if (!result.containsKey('error')) {
      _loadFeed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('✓ Repost updated'),
            backgroundColor: Colors.green,
            duration:        Duration(milliseconds: 1000),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('❌ Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration:        const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showCommentSheet(Post post) async {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        // capture theme colors before entering the builder
        final cardColor    = Theme.of(context).cardColor;
        final dividerColor = Theme.of(context).dividerColor;
        final primaryColor = Theme.of(context).primaryColor;
        final hintColor    = Theme.of(context).textTheme.bodySmall?.color;

        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset:     const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Comments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon:      const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: PostService.getComments(post.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      );
                    }

                    if (snapshot.hasError ||
                        snapshot.data?.containsKey('error') == true) {
                      return Center(
                        child: Text(
                            'Error loading comments: ${snapshot.data?['error'] ?? snapshot.error}'),
                      );
                    }

                    final comments =
                        snapshot.data?['comments'] as List<Comment>? ?? [];

                    return ListView.builder(
                      itemCount:   comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius:          16,
                                    backgroundColor:
                                        primaryColor.withValues(alpha: 0.2),
                                    child: Text(
                                      (comment.creator?['name'] ?? 'U')[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color:      primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize:   12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.creator?['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:   12),
                                        ),
                                        Text(
                                          _formatTime(comment.createdAt),
                                          style: TextStyle(
                                              color:    hintColor,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(comment.content,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.4)),
                              Divider(color: dividerColor, height: 16),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left:   16,
                  right:  16,
                  top:    12,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset:     const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText:  'Add a comment...',
                          hintStyle: TextStyle(color: hintColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (commentController.text.isEmpty) return;
                        final result = await PostService.addComment(
                          post.id, commentController.text);
                        if (!result.containsKey('error')) {
                          commentController.clear();
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                            _loadFeed();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final utcTime    = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final nowUtc     = DateTime.now().toUtc();
    final difference = nowUtc.difference(utcTime);
    final cairoTime  = utcTime.add(const Duration(hours: 2));

    if (difference.inSeconds < 60) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours   < 24) return '${difference.inHours}h ago';
    if (difference.inDays    == 1) return 'Yesterday';
    if (difference.inDays    <  7) return '${difference.inDays}d ago';
    return '${cairoTime.day}/${cairoTime.month}';
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
        title:           const Text('Feed'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
        centerTitle:     isMobile,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFeed),
        ],
      ),
      body: Column(
        children: [
          // ── Create post box ──────────────────────────────────────────
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset:     const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: postController,
                  decoration: InputDecoration(
                    hintText:  "What's on your mind?",
                    hintStyle: TextStyle(color: hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                          color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: primary),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical:   isMobile ? 10 : 12,
                    ),
                  ),
                  maxLines: isMobile ? 2 : 3,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 10 : 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab switcher ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            color:   cardColor,
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                          value: 0,
                          label: Text('Feed'),
                          icon:  Icon(Icons.feed)),
                      ButtonSegment(
                          value: 1,
                          label: Text('My Posts'),
                          icon:  Icon(Icons.person)),
                    ],
                    selected: <int>{selectedTab},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() {
                        selectedTab = newSelection.first;
                        offset      = 0;
                        _loadFeed();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Posts feed ───────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  )
                : posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined,
                                size: 48, color: hintColor),
                            const SizedBox(height: 12),
                            Text('No posts yet',
                                style: TextStyle(
                                    color:      hintColor,
                                    fontSize:   16,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Connect with friends to see their posts',
                                style: TextStyle(
                                    color: hintColor, fontSize: 14)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadFeed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:     const EdgeInsets.all(12),
                        itemCount:   posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:        cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:      Colors.black
                                      .withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset:     const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            primary.withValues(alpha: 0.2),
                                        child: Text(
                                          (post.creator?['name'] ?? 'U')[0]
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color:      primary,
                                            fontWeight: FontWeight.bold,
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
                                              post.creator?['name'] ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:   14),
                                            ),
                                            Text(
                                              _formatTime(post.createdAt),
                                              style: TextStyle(
                                                  color:    hintColor,
                                                  fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(post.content,
                                      style: const TextStyle(
                                          fontSize: 15, height: 1.4)),
                                ),
                                const SizedBox(height: 12),
                                // Actions
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      InkWell(
                                        onTap: () => _likePost(post.id),
                                        child: Column(
                                          children: [
                                            Icon(
                                              post.isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: post.isLiked
                                                  ? Colors.red
                                                  : hintColor,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 4),
                                            Text('${post.likesCount}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: hintColor)),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _showCommentSheet(post),
                                        child: Column(
                                          children: [
                                            Icon(Icons.chat_bubble_outline,
                                                color: hintColor, size: 20),
                                            const SizedBox(height: 4),
                                            Text('${post.commentsCount}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: hintColor)),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _repostPost(post.id),
                                        child: Column(
                                          children: [
                                            Icon(Icons.repeat,
                                                color: post.isReposted
                                                    ? primary
                                                    : hintColor,
                                                size: 20),
                                            const SizedBox(height: 4),
                                            Text('${post.repostsCount}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: hintColor)),
                                          ],
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
          ),
        ],
      ),
    );
  }
}