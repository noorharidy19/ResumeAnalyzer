from pydantic import BaseModel, field_serializer
from typing import Optional
from datetime import datetime

class NotificationCreate(BaseModel):
    notification_type: str
    related_id: str
    triggered_by_id: Optional[str] = None

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    notification_type: str
    related_id: str
    triggered_by_id: Optional[str] = None
    is_read: bool
    created_at: datetime
    
    triggered_by: Optional[dict] = None
    
    @field_serializer('created_at')
    def serialize_datetime(self, value: datetime):
        """Serialize datetime as UTC ISO format with Z suffix"""
        if value.tzinfo is None:
            value = value.replace(tzinfo=None)
        return value.isoformat() + 'Z' if not value.isoformat().endswith('Z') else value.isoformat()
    
    class Config:
        from_attributes = True

class NotificationsListResponse(BaseModel):
    notifications: list[NotificationResponse]
    unread_count: int
