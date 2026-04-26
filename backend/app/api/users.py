from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.user import UserService
from app.services.auth import get_current_user
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/users", tags=["users"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    phone_number: Optional[str] = None
    role: str
    
    class Config:
        from_attributes = True

@router.get("/all", response_model=list[UserResponse])
def get_all_users(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all users (excluding current user)"""
    users = UserService.get_all_users(db, exclude_user_id=current_user["id"])
    return users

@router.get("/search", response_model=list[UserResponse])
def search_users(
    q: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Search users by name or email"""
    users = UserService.search_users(db, q, exclude_user_id=current_user["id"])
    return users

@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific user by ID"""
    user = UserService.get_user_by_id(db, user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user
