from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.user import UserService
from app.services.auth import get_current_user
from app.models.user import User
from pydantic import BaseModel
from typing import Optional
import os
import shutil
from datetime import datetime

router = APIRouter(prefix="/api/users", tags=["users"])

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads/profiles"
os.makedirs(UPLOAD_DIR, exist_ok=True)

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
    profile_picture: Optional[str] = None
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

@router.post("/profile-picture/upload")
async def upload_profile_picture(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload profile picture for current user"""
    user_id = current_user.get("id")
    
    # Validate file
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")
    
    # Check file type
    allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail="File type not allowed. Use jpg, png, gif, or webp")
    
    # Check file size (max 5MB)
    file_size = await file.read()
    await file.seek(0)  # Reset file pointer
    if len(file_size) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File size exceeds 5MB")
    
    try:
        # Generate unique filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{user_id}_{timestamp}{file_ext}"
        filepath = os.path.join(UPLOAD_DIR, filename)
        
        # Save file
        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Update user profile picture path
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Delete old profile picture if exists
        if user.profile_picture and os.path.exists(user.profile_picture):
            try:
                os.remove(user.profile_picture)
            except:
                pass
        
        # Save new path
        user.profile_picture = filepath
        db.commit()
        
        return {
            "message": "Profile picture uploaded successfully",
            "profile_picture": filepath
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading file: {str(e)}")
