import jwt
from datetime import datetime, timedelta
from typing import Optional

# NOTE: For production, load this from environment variables/secrets manager
SECRET_KEY = "dev_secret_change_me"
ALGORITHM = "HS256"


def create_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=24))
    to_encode = {"sub": user_id, "exp": expire}
    token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    # PyJWT returns bytes on older versions, ensure str
    if isinstance(token, bytes):
        token = token.decode()
    return token


def verify_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except Exception:
        return None
