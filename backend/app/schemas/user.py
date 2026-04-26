from pydantic import BaseModel



class SignupSchema(BaseModel):
    name: str
    email: str
    password: str
    phone_number: str


class LoginSchema(BaseModel):
    email: str
    password: str