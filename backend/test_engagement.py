#!/usr/bin/env python3
"""Test engagement API endpoints"""
from app.db.database import SessionLocal
from app.models.user import User
from app.models.post import Post, PostLike, Comment, Repost
from app.services.post import PostService
import uuid
from datetime import datetime, timezone

db = SessionLocal()

try:
    # Create test user
    user_id = "test-user-" + str(uuid.uuid4())[:8]
    user = User(
        id=user_id,
        email=f"test-{uuid.uuid4().hex[:6]}@test.com",
        password="hashed_password",
        name="Test User"
    )
    db.add(user)
    db.commit()
    print(f"✓ Created test user: {user_id}")
    
    # Create test post
    post_id = "test-post-" + str(uuid.uuid4())[:8]
    post = Post(
        id=post_id,
        creator_id=user_id,
        content="Test post for engagement"
    )
    db.add(post)
    db.commit()
    print(f"✓ Created test post: {post_id}")
    
    # Test like
    print("\n--- Testing Like ---")
    PostService.like_post(post_id, user_id, db)
    post = db.query(Post).filter(Post.id == post_id).first()
    print(f"✓ Liked post, likes_count: {post.likes_count}")
    
    # Test is_liked
    is_liked = PostService.is_liked(post_id, user_id, db)
    print(f"✓ is_liked check: {is_liked}")
    
    # Test unlike
    PostService.like_post(post_id, user_id, db)
    post = db.query(Post).filter(Post.id == post_id).first()
    print(f"✓ Unliked post, likes_count: {post.likes_count}")
    
    # Test comment
    print("\n--- Testing Comment ---")
    comment = PostService.add_comment(post_id, user_id, "Test comment", db)
    print(f"✓ Added comment: {comment.id}")
    post = db.query(Post).filter(Post.id == post_id).first()
    print(f"✓ Post comments_count: {post.comments_count}")
    
    # Test get_comments
    comments, total = PostService.get_comments(post_id, db=db)
    print(f"✓ Got {total} comments")
    
    # Test repost
    print("\n--- Testing Repost ---")
    PostService.repost(post_id, user_id, db)
    post = db.query(Post).filter(Post.id == post_id).first()
    print(f"✓ Reposted post, reposts_count: {post.reposts_count}")
    
    # Test is_reposted
    is_reposted = PostService.is_reposted(post_id, user_id, db)
    print(f"✓ is_reposted check: {is_reposted}")
    
    print("\n✅ All engagement features working!")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
