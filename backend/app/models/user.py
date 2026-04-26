from sqlalchemy import Column, String, Enum
from app.db.database import Base
import enum
import uuid
from app.models.enum import UserRole
# 🔥 ENUM

class User(Base):
    __tablename__ = "users"

    # 👇 UUID بدل Integer
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    name = Column(String, nullable=False)

    email = Column(String, unique=True, nullable=False, index=True)

    phone_number = Column(String, unique=True, nullable=True)
    
    profile_picture = Column(String, nullable=True)  # URL to profile picture

    password = Column(String, nullable=False)

    role = Column(Enum(UserRole), default=UserRole.USER, nullable=False)