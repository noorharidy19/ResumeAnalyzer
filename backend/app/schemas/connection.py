from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class UserSimple(BaseModel):
    id: str
    name: str
    email: str
    phone_number: Optional[str] = None
    role: str
    
    class Config:
        from_attributes = True

class ConnectionCreate(BaseModel):
    receiver_id: str

class ConnectionUpdate(BaseModel):
    status: str  # "accepted", "rejected", "blocked"

class ConnectionResponse(BaseModel):
    id: str
    sender_id: str
    receiver_id: str
    status: str
    created_at: datetime
    updated_at: datetime
    
    sender: Optional[UserSimple] = None
    receiver: Optional[UserSimple] = None

    class Config:
        from_attributes = True

class PendingRequestsResponse(BaseModel):
    pending_count: int
    requests: list[ConnectionResponse]

class MyConnectionsResponse(BaseModel):
    connections: list[ConnectionResponse]
    total: int
