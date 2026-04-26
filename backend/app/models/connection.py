from sqlalchemy import Column, String, Enum, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime
import enum
import uuid

class ConnectionStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    BLOCKED = "blocked"

class Connection(Base):
    __tablename__ = "connections"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    sender_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    receiver_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    
    status = Column(Enum(ConnectionStatus, values_callable=lambda x: [e.value for e in x]), default="pending", nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_connections")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="received_connections")
