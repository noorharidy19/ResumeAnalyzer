from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, Enum
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime, timezone
from enum import Enum as PyEnum
import uuid

class NotificationType(str, PyEnum):
    CONNECTION_REQUEST = "connection_request"
    CONNECTION_ACCEPTED = "connection_accepted"
    MESSAGE = "message"
    POST = "post"

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    notification_type = Column(String, nullable=False)
    
    # Reference to related object (connection_id, message_id, post_id, etc)
    related_id = Column(String, nullable=False)
    
    # Who triggered the notification
    triggered_by_id = Column(String, ForeignKey("users.id"), nullable=True)
    
    is_read = Column(Boolean, default=False, nullable=False)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id], backref="notifications")
    triggered_by = relationship("User", foreign_keys=[triggered_by_id])
