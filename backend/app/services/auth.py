from app.models.user import User
import hashlib
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from app.utils.auth_utils import verify_token

security = HTTPBearer()

def signup_user(data, db):

    # 🔥 check if email exists
    existing_user = db.query(User).filter(User.email == data.email).first()

    if existing_user:
        return None  # 👈 مهم

    hashed = hashlib.sha256(data.password.encode()).hexdigest()

    user = User(
        name=data.name,
        email=data.email,
        password=hashed,
        phone_number=data.phone_number
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

def get_current_user(credentials = Depends(security)) -> dict:
    """Verify JWT token and return current user"""
    try:
        token = credentials.credentials
        print(f"Token received: {token[:20]}..." if token else "No token")
        
        user_id = verify_token(token)
        
        if not user_id:
            print("Token verification failed - invalid or expired")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token"
            )
        
        print(f"User authenticated: {user_id}")
        return {"id": user_id}
    except Exception as e:
        print(f"Auth error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )