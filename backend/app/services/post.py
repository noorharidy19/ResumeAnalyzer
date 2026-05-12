from sqlalchemy.orm import Session
from app.models.post import Post, PostLike, Comment, Repost
from app.models.connection import Connection, ConnectionStatus
from sqlalchemy import desc, and_, or_
from datetime import datetime, timezone

class PostService:
    @staticmethod
    def create_post(creator_id: str, content: str, db: Session) -> Post:
        """Create a new post"""
        post = Post(
            creator_id=creator_id,
            content=content
        )
        db.add(post)
        db.commit()
        db.refresh(post)
        return post
    
    @staticmethod
    def get_feed(user_id: str, limit: int = 20, offset: int = 0, db: Session = None) -> tuple[list[Post], int]:
        """Get feed posts from friends and self"""
        # Get all user IDs with accepted connections
        accepted_connections = db.query(Connection).filter(
            Connection.status == ConnectionStatus.ACCEPTED,
            or_(
                Connection.sender_id == user_id,
                Connection.receiver_id == user_id
            )
        ).all()
        
        # Extract friend IDs
        friend_ids = set()
        for conn in accepted_connections:
            if conn.sender_id == user_id:
                friend_ids.add(conn.receiver_id)
            else:
                friend_ids.add(conn.sender_id)
        
        # Include user's own posts
        friend_ids.add(user_id)
        
        # Get posts from friends and self
        query = db.query(Post).filter(Post.creator_id.in_(friend_ids)).order_by(desc(Post.created_at))
        
        total_count = query.count()
        posts = query.offset(offset).limit(limit).all()
        return posts, total_count
    
    @staticmethod
    def get_user_posts(user_id: str, limit: int = 20, offset: int = 0, db: Session = None) -> tuple[list[Post], int]:
        """Get user's own posts"""
        query = db.query(Post).filter(Post.creator_id == user_id).order_by(desc(Post.created_at))
        total_count = query.count()
        posts = query.offset(offset).limit(limit).all()
        return posts, total_count
    
    @staticmethod
    def get_post(post_id: str, db: Session) -> Post:
        """Get a specific post"""
        return db.query(Post).filter(Post.id == post_id).first()
    
    @staticmethod
    def delete_post(post_id: str, db: Session) -> bool:
        """Delete a post"""
        post = db.query(Post).filter(Post.id == post_id).first()
        if post:
            db.delete(post)
            db.commit()
            return True
        return False
    
    @staticmethod
    def like_post(post_id: str, user_id: str, db: Session) -> bool:
        """Like a post"""
        # Check if already liked
        existing_like = db.query(PostLike).filter(
            PostLike.post_id == post_id,
            PostLike.user_id == user_id
        ).first()
        
        if existing_like:
            # Unlike
            db.delete(existing_like)
            post = db.query(Post).filter(Post.id == post_id).first()
            if post and post.likes_count > 0:
                post.likes_count -= 1
        else:
            # Like
            like = PostLike(post_id=post_id, user_id=user_id)
            db.add(like)
            post = db.query(Post).filter(Post.id == post_id).first()
            if post:
                post.likes_count += 1
        
        db.commit()
        return True
    
    @staticmethod
    def add_comment(post_id: str, creator_id: str, content: str, db: Session) -> Comment:
        """Add a comment to a post"""
        comment = Comment(
            post_id=post_id,
            creator_id=creator_id,
            content=content
        )
        db.add(comment)
        
        # Update comment count
        post = db.query(Post).filter(Post.id == post_id).first()
        if post:
            post.comments_count += 1
        
        db.commit()
        db.refresh(comment)
        return comment
    
    @staticmethod
    def delete_comment(comment_id: str, db: Session) -> bool:
        """Delete a comment"""
        comment = db.query(Comment).filter(Comment.id == comment_id).first()
        if comment:
            post = db.query(Post).filter(Post.id == comment.post_id).first()
            if post and post.comments_count > 0:
                post.comments_count -= 1
            db.delete(comment)
            db.commit()
            return True
        return False
    
    @staticmethod
    def get_comments(post_id: str, limit: int = 20, offset: int = 0, db: Session = None) -> tuple[list[Comment], int]:
        """Get comments for a post"""
        query = db.query(Comment).filter(Comment.post_id == post_id).order_by(desc(Comment.created_at))
        total_count = query.count()
        comments = query.offset(offset).limit(limit).all()
        return comments, total_count
    
    @staticmethod
    def repost(post_id: str, user_id: str, db: Session) -> bool:
        """Repost a post"""
        # Check if already reposted
        existing_repost = db.query(Repost).filter(
            Repost.post_id == post_id,
            Repost.user_id == user_id
        ).first()
        
        if existing_repost:
            # Remove repost
            db.delete(existing_repost)
            post = db.query(Post).filter(Post.id == post_id).first()
            if post and post.reposts_count > 0:
                post.reposts_count -= 1
        else:
            # Add repost
            repost = Repost(post_id=post_id, user_id=user_id)
            db.add(repost)
            post = db.query(Post).filter(Post.id == post_id).first()
            if post:
                post.reposts_count += 1
        
        db.commit()
        return True
    
    @staticmethod
    def is_liked(post_id: str, user_id: str, db: Session) -> bool:
        """Check if user has liked a post"""
        return db.query(PostLike).filter(
            PostLike.post_id == post_id,
            PostLike.user_id == user_id
        ).first() is not None
    
    @staticmethod
    def is_reposted(post_id: str, user_id: str, db: Session) -> bool:
        """Check if user has reposted a post"""
        return db.query(Repost).filter(
            Repost.post_id == post_id,
            Repost.user_id == user_id
        ).first() is not None
