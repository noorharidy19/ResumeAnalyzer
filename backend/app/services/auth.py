from app.models.user import User
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from app.utils.auth_utils import verify_token

security    = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def signup_user(data, db):
    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        return None

    user = User(
        name         = data.name,
        email        = data.email,
        password     = pwd_context.hash(data.password),
        phone_number = data.phone_number,
        role         = data.role,                        # ← was missing
    )

    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def login_user(data, db):
    user = db.query(User).filter(User.email == data.email).first()

    if not user or not pwd_context.verify(data.password, user.password):
        return None

    return user


def get_current_user(credentials=Depends(security)) -> dict:
    token   = credentials.credentials
    user_id = verify_token(token)

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return {"id": user_id}