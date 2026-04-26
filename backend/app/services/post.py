from sqlalchemy.orm import Session
from app.models.post import Post
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
        """Get feed posts from friends only (accepted connections)"""
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
        
        # Get posts from friends
        if friend_ids:
            query = db.query(Post).filter(Post.creator_id.in_(friend_ids)).order_by(desc(Post.created_at))
        else:
            query = db.query(Post).filter(False)  # Return empty if no friends
        
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
    def like_post(post_id: str, db: Session) -> bool:
        """Increment likes count"""
        post = db.query(Post).filter(Post.id == post_id).first()
        if post:
            post.likes_count += 1
            db.commit()
            db.refresh(post)
            return True
        return False
