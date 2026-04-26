from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.auth import get_current_user
from app.schemas.notification import NotificationResponse, NotificationsListResponse
from app.services.notification import NotificationService
from app.models.user import User

router = APIRouter(
    prefix="/api/notifications",
    tags=["notifications"],
    dependencies=[Depends(get_current_user)]
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/")
def get_notifications(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's notifications"""
    user_id = current_user.get("id")
    notifications, total_count = NotificationService.get_notifications(user_id, limit, offset, db)
    
    # Enrich with triggered_by user data
    notifications_data = []
    for notif in notifications:
        triggered_by_user = None
        if notif.triggered_by_id:
            triggered_by_user = db.query(User).filter(User.id == notif.triggered_by_id).first()
        
        notifications_data.append({
            "id": notif.id,
            "user_id": notif.user_id,
            "notification_type": notif.notification_type,
            "related_id": notif.related_id,
            "triggered_by_id": notif.triggered_by_id,
            "is_read": notif.is_read,
            "created_at": notif.created_at,
            "triggered_by": {
                "id": triggered_by_user.id,
                "name": triggered_by_user.name,
                "email": triggered_by_user.email
            } if triggered_by_user else None
        })
    
    unread_count = NotificationService.get_unread_notifications_count(user_id, db)
    
    return {
        "notifications": notifications_data,
        "unread_count": unread_count
    }

@router.get("/unread-count")
def get_unread_count(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get unread notifications count"""
    user_id = current_user.get("id")
    count = NotificationService.get_unread_notifications_count(user_id, db)
    return {"unread_count": count}

@router.patch("/{notification_id}/read")
def mark_as_read(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark notification as read"""
    notif = NotificationService.mark_as_read(notification_id, db)
    if not notif:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    return {"status": "marked as read"}

@router.patch("/read-all")
def mark_all_as_read(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark all notifications as read"""
    user_id = current_user.get("id")
    count = NotificationService.mark_all_as_read(user_id, db)
    return {"status": "marked all as read", "count": count}

@router.delete("/{notification_id}")
def delete_notification(
    notification_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a notification"""
    if not NotificationService.delete_notification(notification_id, db):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    return {"status": "deleted"}
