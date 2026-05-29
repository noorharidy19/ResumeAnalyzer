from pydantic import BaseModel, EmailStr
from typing import Optional
 
 
class SignupSchema(BaseModel):
    name:         str
    email:        str
    phone_number: str
    password:     str
    role:         Optional[str] = "user"   # "user" or "company"
 
 
class LoginSchema(BaseModel):
    email:    str
    password: str
 
 
class UserResponse(BaseModel):
    id:           int
    name:         str
    email:        str
    phone_number: Optional[str] = None
    role:         str
    profile_picture: Optional[str] = None
 
    class Config:
        from_attributes = True
 
 
class LoginResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"
    user:         UserResponse
 