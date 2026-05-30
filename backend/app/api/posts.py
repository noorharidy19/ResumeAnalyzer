from fastapi import APIRouter, Depends, HTTPException, status, Query
import traceback
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.auth import get_current_user
from app.schemas.post import PostCreate, PostResponse, FeedResponse, CommentCreate, CommentResponse
from app.services.post import PostService
from app.services.notification import NotificationService
from app.models.user import User
from app.models.connection import Connection, ConnectionStatus
from sqlalchemy import or_

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

def format_post(post, user_id: str, db: Session):
    """Format post with engagement status"""
    creator = db.query(User).filter(User.id == post.creator_id).first()
    is_liked = PostService.is_liked(post.id, user_id, db)
    is_reposted = PostService.is_reposted(post.id, user_id, db)
    
    return {
        "id": post.id,
        "creator_id": post.creator_id,
        "content": post.content,
        "likes_count": post.likes_count,
        "comments_count": post.comments_count,
        "reposts_count": post.reposts_count,
        "is_liked": is_liked,
        "is_reposted": is_reposted,
        "created_at": post.created_at,
        "updated_at": post.updated_at,
        "creator": {
            "id": creator.id,
            "name": creator.name,
            "email": creator.email
        } if creator else None
    }

@router.post("/create")
def create_post(
    post_data: PostCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new post"""
    user_id = current_user.id
    post = PostService.create_post(user_id, post_data.content, db)
    
    # Get accepted connections (friends only)
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
    
    # Create notifications only for friends
    for friend_id in friend_ids:
        NotificationService.create_notification(
            user_id=friend_id,
            notification_type="post",
            related_id=post.id,
            triggered_by_id=user_id,
            db=db
        )
    
    return format_post(post, user_id, db)

@router.get("/feed")
def get_feed(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get feed posts"""
    try:
        user_id = current_user.id
        posts, total_count = PostService.get_feed(user_id, limit, offset, db)

        # Format posts with engagement status
        posts_data = [format_post(post, user_id, db) for post in posts]

        return {
            "posts": posts_data,
            "total_count": total_count
        }
    except Exception as e:
        tb = traceback.format_exc()
        # Include traceback in the error detail to aid debugging during development
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"{str(e)}\n\nTraceback:\n{tb}"
        )

@router.get("/my-posts")
def get_my_posts(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's own posts"""
    user_id = current_user.id
    posts, total_count = PostService.get_user_posts(user_id, limit, offset, db)
    
    # Format posts with engagement status
    posts_data = [format_post(post, user_id, db) for post in posts]
    
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
    """Toggle like on a post"""
    user_id =current_user.id
    post = PostService.get_post(post_id, db)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    is_liked = PostService.is_liked(post_id, user_id, db)
    PostService.like_post(post_id, user_id, db)
    
    # Create notification for post creator (only if not self-like and not already liked)
    if not is_liked and post.creator_id != user_id:
        NotificationService.create_notification(
            user_id=post.creator_id,
            notification_type="post_like",
            related_id=post.id,
            triggered_by_id=user_id,
            db=db
        )
    
    # Refresh post data and return updated post
    post = PostService.get_post(post_id, db)
    return format_post(post, user_id, db)

@router.post("/{post_id}/comment")
def add_comment(
    post_id: str,
    comment_data: CommentCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add a comment to a post"""
    user_id = current_user.id
    post = PostService.get_post(post_id, db)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    comment = PostService.add_comment(post_id, user_id, comment_data.content, db)
    
    # Create notification for post creator
    if post.creator_id != user_id:
        NotificationService.create_notification(
            user_id=post.creator_id,
            notification_type="post_comment",
            related_id=post.id,
            triggered_by_id=user_id,
            db=db
        )
    
    # Return updated post with new comments_count
    post = PostService.get_post(post_id, db)
    return format_post(post, user_id, db)

@router.get("/{post_id}/comments")
def get_comments(
    post_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get comments for a post"""
    post = PostService.get_post(post_id, db)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    comments, total_count = PostService.get_comments(post_id, limit, offset, db)
    
    comments_data = []
    for comment in comments:
        creator = db.query(User).filter(User.id == comment.creator_id).first()
        comments_data.append({
            "id": comment.id,
            "post_id": comment.post_id,
            "creator_id": comment.creator_id,
            "content": comment.content,
            "created_at": comment.created_at,
            "updated_at": comment.updated_at,
            "creator": {
                "id": creator.id,
                "name": creator.name,
                "email": creator.email
            } if creator else None
        })
    
    return {
        "comments": comments_data,
        "total_count": total_count
    }

@router.delete("/{post_id}/comment/{comment_id}")
def delete_comment(
    post_id: str,
    comment_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a comment"""
    user_id = current_user.id
    from app.models.post import Comment
    
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    
    if not comment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comment not found"
        )
    
    if comment.creator_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete comment from another user"
        )
    
    if not PostService.delete_comment(comment_id, db):
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete comment"
        )
    
    return {"status": "deleted"}

@router.post("/{post_id}/repost")
def repost(
    post_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Toggle repost on a post"""
    user_id = current_user.id
    post = PostService.get_post(post_id, db)
    
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found"
        )
    
    is_reposted = PostService.is_reposted(post_id, user_id, db)
    PostService.repost(post_id, user_id, db)
    
    # Create notification for post creator (only if not self-repost and not already reposted)
    if not is_reposted and post.creator_id != user_id:
        NotificationService.create_notification(
            user_id=post.creator_id,
            notification_type="post_repost",
            related_id=post.id,
            triggered_by_id=user_id,
            db=db
        )
    
    # Return updated post
    post = PostService.get_post(post_id, db)
    return format_post(post, user_id, db)

@router.delete("/{post_id}")
def delete_post(
    post_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a post"""
    user_id = current_user.id
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
