from sqlalchemy.orm import Session
from app.models.notification import Notification
from sqlalchemy import desc, and_

class NotificationService:
    @staticmethod
    def create_notification(user_id: str, notification_type: str, related_id: str, 
                          triggered_by_id: str = None, db: Session = None) -> Notification:
        """Create a new notification"""
        notification = Notification(
            user_id=user_id,
            notification_type=notification_type,
            related_id=related_id,
            triggered_by_id=triggered_by_id
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification
    
    @staticmethod
    def get_notifications(user_id: str, limit: int = 20, offset: int = 0, 
                         db: Session = None) -> tuple[list[Notification], int]:
        """Get user's notifications"""
        query = db.query(Notification).filter(
            Notification.user_id == user_id
        ).order_by(desc(Notification.created_at))
        total_count = query.count()
        notifications = query.offset(offset).limit(limit).all()
        return notifications, total_count
    
    @staticmethod
    def get_unread_notifications_count(user_id: str, db: Session) -> int:
        """Get unread notifications count"""
        count = db.query(Notification).filter(
            and_(
                Notification.user_id == user_id,
                Notification.is_read == False
            )
        ).count()
        return count
    
    @staticmethod
    def mark_as_read(notification_id: str, db: Session) -> Notification:
        """Mark notification as read"""
        notification = db.query(Notification).filter(
            Notification.id == notification_id
        ).first()
        if notification:
            notification.is_read = True
            db.commit()
            db.refresh(notification)
        return notification
    
    @staticmethod
    def mark_all_as_read(user_id: str, db: Session) -> int:
        """Mark all user notifications as read"""
        notifications = db.query(Notification).filter(
            and_(
                Notification.user_id == user_id,
                Notification.is_read == False
            )
        ).all()
        count = 0
        for notif in notifications:
            notif.is_read = True
            count += 1
        db.commit()
        return count
    
    @staticmethod
    def delete_notification(notification_id: str, db: Session) -> bool:
        """Delete a notification"""
        notification = db.query(Notification).filter(
            Notification.id == notification_id
        ).first()
        if notification:
            db.delete(notification)
            db.commit()
            return True
        return False
