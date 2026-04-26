from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.user import SignupSchema
from app.schemas.user import LoginSchema
from app.services.auth import login_user, signup_user
from app.db.database import SessionLocal

router = APIRouter(prefix="/auth", tags=["Auth"])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


from fastapi import HTTPException

@router.post("/signup")
def signup(data: SignupSchema, db: Session = Depends(get_db)):
    user = signup_user(data, db)

    if not user:
        raise HTTPException(status_code=400, detail="Email already exists")

    return {"message": "created", "user_id": str(user.id)}

from app.utils.auth_utils import create_token

@router.post("/login")
def login(data: LoginSchema, db: Session = Depends(get_db)):
    user = login_user(data, db)

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or password")

    token = create_token(str(user.id))

    return {
        "access_token": token,
        "user": {
            "id": str(user.id),
            "email": user.email,
            "name": user.name
        }
    }