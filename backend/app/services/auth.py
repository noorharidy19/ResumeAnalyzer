from app.models.user import User
import hashlib
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from app.utils.auth_utils import verify_token
from sqlalchemy.orm import Session
from app.db.database import get_db

security = HTTPBearer()

def signup_user(data, db):
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        return None

    hashed = hashlib.sha256(data.password.encode()).hexdigest()

    user = User(
        name         = data.name,
        email        = data.email,
        password     = hashed,
        phone_number = data.phone_number,
        role         = getattr(data, 'role', 'user')
    )

    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def login_user(data, db):
    hashed = hashlib.sha256(data.password.encode()).hexdigest()
    user = db.query(User).filter(User.email == data.email).first()
    if not user or user.password != hashed:
        return None
    return user

def get_current_user(credentials=Depends(security), db: Session = Depends(get_db)) -> dict:
    try:
        token = credentials.credentials
        user_id = verify_token(token)
        if not user_id:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
        
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
        
        return user  # ← return the full User object
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication credentials")