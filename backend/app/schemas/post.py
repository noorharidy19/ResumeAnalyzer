from pydantic import BaseModel, field_serializer
from typing import Optional
from datetime import datetime

class PostCreate(BaseModel):
    content: str

class PostResponse(BaseModel):
    id: str
    creator_id: str
    content: str
    likes_count: int
    created_at: datetime
    updated_at: datetime
    
    creator: Optional[dict] = None
    
    @field_serializer('created_at', 'updated_at')
    def serialize_datetime(self, value: datetime):
        """Serialize datetime as UTC ISO format with Z suffix"""
        if value.tzinfo is None:
            value = value.replace(tzinfo=None)
        return value.isoformat() + 'Z' if not value.isoformat().endswith('Z') else value.isoformat()
    
    class Config:
        from_attributes = True

class FeedResponse(BaseModel):
    posts: list[PostResponse]
    total_count: int
