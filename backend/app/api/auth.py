from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.schemas.user import SignupSchema, LoginSchema
from app.services.auth import login_user, signup_user
from app.utils.auth_utils import create_token
from app.db.database import SessionLocal

router = APIRouter(prefix="/auth", tags=["Auth"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/signup", status_code=201)
def signup(data: SignupSchema, db: Session = Depends(get_db)):
    user = signup_user(data, db)

    if not user:
        raise HTTPException(status_code=400, detail="Email already exists")

    return {"message": "Account created successfully", "user_id": str(user.id)}


@router.post("/login")
def login(data: LoginSchema, db: Session = Depends(get_db)):
    user = login_user(data, db)

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_token(str(user.id))

    return {
        "access_token": token,
        "token_type":   "bearer",
        "user": {
            "id":              str(user.id),
            "name":            user.name,
            "email":           user.email,
            "role":            user.role,
            "profile_picture": user.profile_picture,
        },
    }