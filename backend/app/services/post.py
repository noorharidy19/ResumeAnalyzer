from sqlalchemy.orm import Session
from app.models.post import Post
from sqlalchemy import desc, and_
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
        """Get feed posts (all posts including user's own, ordered by newest first)"""
        query = db.query(Post).order_by(desc(Post.created_at))
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
