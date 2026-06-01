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
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all users (excluding current user)"""
    users = UserService.get_all_users(db, exclude_user_id=current_user.id)
    return users

@router.get("/search", response_model=list[UserResponse])
def search_users(
    q: str,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Search users by name or email"""
    users = UserService.search_users(db, q, exclude_user_id=current_user.id)
    return users

@router.get("/{user_id}", response_model=UserResponse)
def get_user(
    user_id: str,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific user by ID"""
    user = UserService.get_user_by_id(db, user_id)
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user

BASE_URL = "http://192.168.1.5:8001"  # ✅ add this near the top of the file

@router.post("/profile-picture/upload")
async def upload_profile_picture(
    file: UploadFile = File(...),
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_id = current_user.id

    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided")

    allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail="File type not allowed.")

    file_size = await file.read()
    await file.seek(0)
    if len(file_size) > 5 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File size exceeds 5MB")

    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{user_id}_{timestamp}{file_ext}"
        filepath = f"{UPLOAD_DIR}/{filename}"  # ✅ forward slash, no os.path.join

        with open(filepath, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        if user.profile_picture:
            # Extract local path from old URL if needed
            old_path = user.profile_picture.replace(f"{BASE_URL}/", "")
            if os.path.exists(old_path):
                try:
                    os.remove(old_path)
                except:
                    pass

        # ✅ Save full URL to DB
        full_url = f"{BASE_URL}/{filepath}"
        user.profile_picture = full_url
        db.commit()

        return {
            "message": "Profile picture uploaded successfully",
            "profile_picture": full_url
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading file: {str(e)}")


@router.delete("/profile-picture")
def delete_profile_picture(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete current user's profile picture"""
    user_id = current_user.id

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    try:
        if user.profile_picture and os.path.exists(user.profile_picture):
            try:
                os.remove(user.profile_picture)
            except Exception:
                pass

        user.profile_picture = None
        db.commit()

        return {"message": "Profile picture deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting profile picture: {str(e)}")


@router.put("/profile")
def update_profile(
    payload: dict,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's profile (name, phone_number)"""
    user_id = current_user.id

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    name = payload.get('name')
    phone_number = payload.get('phone_number')

    # Validate required fields
    if not name:
        raise HTTPException(status_code=400, detail="Name is required")

    # If phone number provided, check uniqueness
    if phone_number:
        existing = db.query(User).filter(User.phone_number == phone_number, User.id != user_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="Phone number already in use by another account")

    # Update
    user.name = name
    user.phone_number = phone_number
    db.commit()

    return {
        "message": "Profile updated",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone_number": user.phone_number,
            "profile_picture": user.profile_picture
        }
    }
