from pydantic import BaseModel, field_serializer
from typing import Optional
from datetime import datetime

class MessageCreate(BaseModel):
    content: str

class MessageUpdate(BaseModel):
    is_read: Optional[bool] = None

class MessageResponse(BaseModel):
    id: str
    sender_id: str
    receiver_id: str
    content: str
    is_read: bool
    created_at: datetime
    updated_at: datetime
    
    sender: Optional[dict] = None
    receiver: Optional[dict] = None
    
    @field_serializer('created_at', 'updated_at')
    def serialize_datetime(self, value: datetime):
        """Serialize datetime as UTC ISO format with Z suffix"""
        if value.tzinfo is None:
            # Naive datetime - assume UTC
            value = value.replace(tzinfo=None)
        return value.isoformat() + 'Z' if not value.isoformat().endswith('Z') else value.isoformat()
    
    class Config:
        from_attributes = True

class ChatHistoryResponse(BaseModel):
    messages: list[MessageResponse]
    other_user: dict
    unread_count: int
