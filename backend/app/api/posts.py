from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.auth import get_current_user
from app.schemas.post import PostCreate, PostResponse, FeedResponse
from app.services.post import PostService
from app.services.notification import NotificationService
from app.models.user import User

router = APIRouter(
    prefix="/api/posts",
    tags=["posts"],
    dependencies=[Depends(get_current_user)]
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/create")
def create_post(
    post_data: PostCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new post"""
    user_id = current_user.get("id")
    post = PostService.create_post(user_id, post_data.content, db)
    
    # Get user info
    user = db.query(User).filter(User.id == user_id).first()
    
    # Create notifications for all other users
    all_users = db.query(User).filter(User.id != user_id).all()
    for other_user in all_users:
        NotificationService.create_notification(
            user_id=other_user.id,
            notification_type="post",
            related_id=post.id,
            triggered_by_id=user_id,
            db=db
        )
    
    return {
        "id": post.id,
        "creator_id": post.creator_id,
        "content": post.content,
        "likes_count": post.likes_count,
        "created_at": post.created_at,
        "updated_at": post.updated_at,
        "creator": {
            "id": user.id,
            "name": user.name,
            "email": user.email
        } if user else None
    }

@router.get("/feed")
def get_feed(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get feed posts"""
    user_id = current_user.get("id")
    posts, total_count = PostService.get_feed(user_id, limit, offset, db)
    
    # Enrich with creator data
    posts_data = []
    for post in posts:
        creator = db.query(User).filter(User.id == post.creator_id).first()
        posts_data.append({
            "id": post.id,
            "creator_id": post.creator_id,
            "content": post.content,
            "likes_count": post.likes_count,
            "created_at": post.created_at,
            "updated_at": post.updated_at,
            "creator": {
                "id": creator.id,
                "name": creator.name,
                "email": creator.email
            } if creator else None
        })
    
    return {
        "posts": posts_data,
        "total_count": total_count
    }

@router.get("/my-posts")
def get_my_posts(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's own posts"""
    user_id = current_user.get("id")
    posts, total_count = PostService.get_user_posts(user_id, limit, offset, db)
    
    # Enrich with creator data
    user = db.query(User).filter(User.id == user_id).first()
    posts_data = []
    for post in posts:
        posts_data.append({
            "id": post.id,
            "creator_id": post.creator_id,
            "content": post.content,
            "likes_count": post.likes_count,
            "created_at": post.created_at,
            "updated_at": post.updated_at,
            "creator": {
                "id": user.id,
                "name": user.name,
                "email": user.email
            } if user else None
        })
    
    return {
        "posts": posts_data,
        "total_count": total_count
    }

@router.post("/{post_id}/like")
def like_post(
    post_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Like a post"""
    user_id = current_user.get("id")
    post = PostService.get_post(post_id, db)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    if not PostService.like_post(post_id, db):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    # Create notification for post creator (only if not self-like)
    if post.creator_id != user_id:
        NotificationService.create_notification(
            user_id=post.creator_id,
            notification_type="post_like",
            related_id=post.id,
            triggered_by_id=user_id,
            db=db
        )
    
    return {"status": "liked"}

@router.delete("/{post_id}")
def delete_post(
    post_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a post"""
    user_id = current_user.get("id")
    post = PostService.get_post(post_id, db)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    if post.creator_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete post from another user"
        )
    
    if not PostService.delete_post(post_id, db):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete post"
        )
    
    return {"status": "deleted"}
