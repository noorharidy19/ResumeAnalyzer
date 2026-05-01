from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.api import auth, connections, users, messages, posts, notifications, resume
import os

app = FastAPI()

app.include_router(auth.router)
app.include_router(connections.router)
app.include_router(users.router)
app.include_router(messages.router)
app.include_router(posts.router)
app.include_router(notifications.router)
app.include_router(resume.router)

# Mount static files for uploads
if not os.path.exists("uploads"):
    os.makedirs("uploads")
if os.path.exists("uploads/profiles"):
    app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)