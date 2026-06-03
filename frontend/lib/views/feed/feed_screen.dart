import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../utils/responsive_helper.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Color get primary => Theme.of(context).primaryColor;

  List<Post> posts      = [];
  bool isLoading        = true;
  int  totalCount       = 0;
  int  offset           = 0;
  final int limit       = 20;
  final TextEditingController postController = TextEditingController();
  int selectedTab       = 0;

  // ── Local interactivity state ─────────────────────────────────────────────
  final Set<String> _bookmarks  = {};   // bookmarked post ids
  final Set<String> _hiddenPosts = {};   // hidden post ids (local only)
  String _sortBy = 'newest';           // newest | oldest | most_liked

  static const _sortOptions = {
    'newest':     'Newest First',
    'oldest':     'Oldest First',
    'most_liked': 'Most Liked',
  };

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Error loading ${selectedTab == 0 ? "feed" : "posts"}: ${result['error']}'),
          backgroundColor: Colors.red,
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('Post created! ✓'),
          backgroundColor: Colors.green,
          duration:        Duration(milliseconds: 800),
        ));
      }
      setState(() { selectedTab = 1; offset = 0; });
      _loadFeed();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Error: ${result['error']}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _likePost(String postId) async {
    final result = await PostService.likePost(postId);
    if (!result.containsKey('error')) {
      _loadFeed();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text('❌ Error: ${result['error']}'),
        backgroundColor: Colors.red,
        duration:        const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _repostPost(String postId) async {
    final result = await PostService.repost(postId);
    if (!result.containsKey('error')) {
      _loadFeed();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text('❌ Error: ${result['error']}'),
        backgroundColor: Colors.red,
        duration:        const Duration(seconds: 3),
      ));
    }
  }

  // ── Bookmark toggle ───────────────────────────────────────────────────────
  void _toggleBookmark(String postId) {
    setState(() {
      if (_bookmarks.contains(postId)) {
        _bookmarks.remove(postId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:  Text('Bookmark removed'),
          duration: Duration(seconds: 2),
        ));
      } else {
        _bookmarks.add(postId);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('Post bookmarked 🔖'),
          backgroundColor: Colors.indigo,
          duration:        Duration(seconds: 2),
        ));
      }
    });
  }

  // ── Delete own post with undo ─────────────────────────────────────────────
  void _deletePost(Post post, int index) {
  setState(() => posts.removeAt(index));

  bool undone = false;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content:  const Text('Post deleted'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label:     'Undo',
        textColor: Colors.yellow,
        onPressed: () {
          undone = true;
          setState(() => posts.insert(index, post));
        },
      ),
    ),
  ).closed.then((_) async {
    if (!undone) {
      final result = await PostService.deletePost(post.id);
      if (result.containsKey('error') && mounted) {
        // Restore the post if API call failed
        setState(() => posts.insert(index, post));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Failed to delete: ${result['error']}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  });
}

  // ── Hide post (all-posts tab, local only) ────────────────────────────────
  void _hidePost(Post post) {
    setState(() => _hiddenPosts.add(post.id));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:  const Text('Post hidden'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label:     'Undo',
          textColor: Colors.yellow,
          onPressed: () => setState(() => _hiddenPosts.remove(post.id)),
        ),
      ),
    );
  }

  // ── Sorted list ───────────────────────────────────────────────────────────
  List<Post> get _sorted {
    final list = posts.where((p) => !_hiddenPosts.contains(p.id)).toList();
    switch (_sortBy) {
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'most_liked':
        list.sort((a, b) => b.likesCount.compareTo(a.likesCount));
      default: // newest
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _showCommentSheet(Post post) async {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
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
                    Text('Comments',
                        style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.bold,
                            color:      primaryColor)),
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
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(primaryColor)));
                    }
                    final comments =
                        (snap.data!['comments'] as List<Comment>?) ?? [];
                    if (comments.isEmpty) {
                      return Center(
                          child: Text('No comments yet',
                              style: TextStyle(color: hintColor)));
                    }
                    return ListView.separated(
                      padding:          const EdgeInsets.all(16),
                      itemCount:        comments.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: dividerColor),
                      itemBuilder: (_, i) {
                        final c = comments[i];  // ← cast to Comment, not Map
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.2),
                            child: Text(
                              (c.creator?['name'] ?? 'U')[0].toUpperCase(),
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                          title: Text(
                            c.creator?['name'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(c.content, style: const TextStyle(fontSize: 14)),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16,
                    MediaQuery.of(sheetContext).viewInsets.bottom + 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(
                      top: BorderSide(color: dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller:  commentController,
                        decoration: InputDecoration(
                          hintText:  'Add a comment…',
                          hintStyle: TextStyle(color: hintColor),
                          border:    InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon:  Icon(Icons.send, color: primaryColor),
                      onPressed: () async {
                        if (commentController.text.trim().isEmpty) return;
                        await PostService.addComment(
                            post.id, commentController.text.trim());
                        commentController.clear();
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                        _loadFeed();
                      },
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

  @override
  Widget build(BuildContext context) {
    final isMobile  = ResponsiveHelper.isMobile(context);
    final cardColor = Theme.of(context).cardColor;
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;
    final sorted    = _sorted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Feed'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
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
        ],
      ),
      body: Column(
        children: [
          // ── Tab bar ───────────────────────────────────────────────────────
          Container(
            color: primary,
            child: Row(
              children: ['All Posts', 'My Posts'].asMap().entries.map((e) {
                final isSelected = selectedTab == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() { selectedTab = e.key; offset = 0; });
                      _loadFeed();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:  isSelected ? Colors.white : Colors.transparent,
                            width:  3,
                          ),
                        ),
                      ),
                      child: Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:      isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Post composer ─────────────────────────────────────────────────
          Container(
            padding:   const EdgeInsets.all(12),
            color:     cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: postController,
                    decoration: InputDecoration(
                      hintText:    "What's on your mind?",
                      hintStyle:   TextStyle(color: hintColor),
                      border:      OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide(color: primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide(color: primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Post'),
                ),
              ],
            ),
          ),

          // ── Posts feed ────────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primary)))
                : sorted.isEmpty
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
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadFeed,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:     const EdgeInsets.all(12),
                        itemCount:   sorted.length,
                        itemBuilder: (context, index) {
                          final post       = sorted[index];
                          final isBookmark = _bookmarks.contains(post.id);
                          final isMyPost   = selectedTab == 1;
                          final realIndex  = posts.indexOf(post);

                          return Dismissible(
                            key:       ValueKey(post.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => isMyPost
                                ? _deletePost(post, realIndex)
                                : _hidePost(post),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:   const EdgeInsets.symmetric(
                                  horizontal: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:        isMyPost ? Colors.red : Colors.grey[700]!,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isMyPost ? Icons.delete_outline : Icons.visibility_off,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 6),
                                  Text(isMyPost ? 'Delete' : 'Hide',
                                      style: const TextStyle(
                                          color:      Colors.white,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:        cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: isBookmark
                                    ? Border.all(
                                        color: Colors.indigo,
                                        width: 1.5)
                                    : null,
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
                                  // ── Post header ───────────────────────
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius:          20,
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
                                        // ── Bookmark button ───────────
                                        IconButton(
                                          icon: Icon(
                                            isBookmark
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: isBookmark
                                                ? Colors.indigo
                                                : hintColor,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _toggleBookmark(post.id),
                                          tooltip: isBookmark
                                              ? 'Remove bookmark'
                                              : 'Bookmark',
                                        ),
                                        // ── More options menu ─────────
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_vert,
                                              color: hintColor, size: 20),
                                          onSelected: (value) {
                                            if (value == 'delete') {
                                              _deletePost(post, realIndex);
                                            } else if (value == 'hide') {
                                              _hidePost(post);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            if (isMyPost)
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(children: [
                                                  Icon(Icons.delete_outline,
                                                      color: Colors.red, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Delete post',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ]),
                                              ),
                                            if (!isMyPost)
                                              const PopupMenuItem(
                                                value: 'hide',
                                                child: Row(children: [
                                                  Icon(Icons.visibility_off,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Hide post'),
                                                ]),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ── Content ───────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(post.content,
                                        style: const TextStyle(
                                            fontSize: 15, height: 1.4)),
                                  ),
                                  const SizedBox(height: 12),
                                  // ── Action row ────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        InkWell(
                                          onTap: () => _likePost(post.id),
                                          child: Column(children: [
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
                                                    color:    hintColor)),
                                          ]),
                                        ),
                                        InkWell(
                                          onTap: () =>
                                              _showCommentSheet(post),
                                          child: Column(children: [
                                            Icon(Icons.chat_bubble_outline,
                                                color: hintColor, size: 20),
                                            const SizedBox(height: 4),
                                            Text('${post.commentsCount}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:    hintColor)),
                                          ]),
                                        ),
                                        InkWell(
                                          onTap: () => _repostPost(post.id),
                                          child: Column(children: [
                                            Icon(Icons.repeat,
                                                color: post.isReposted
                                                    ? primary
                                                    : hintColor,
                                                size: 20),
                                            const SizedBox(height: 4),
                                            Text('${post.repostsCount}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:    hintColor)),
                                          ]),
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
          ),
        ],
      ),
    );
  }
}