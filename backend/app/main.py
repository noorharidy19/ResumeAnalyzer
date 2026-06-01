from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.api import auth, connections, users, messages, posts, notifications, resume, cv_enhancement
import os
from app.db.database import Base, engine
from app.models.user import User
from app.api import jobs, applications
from fastapi.middleware.cors import CORSMiddleware
from app.models.resume_analysis import ResumeAnalysis       

Base.metadata.create_all(bind=engine)

app = FastAPI()

# ── MIDDLEWARE ──────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── THEN ROUTERS ──────────────────────────────────────────────
app.include_router(jobs.router)
app.include_router(applications.router)
app.include_router(auth.router)
app.include_router(connections.router)
app.include_router(users.router)
app.include_router(messages.router)
app.include_router(posts.router)
app.include_router(notifications.router)
app.include_router(resume.router)
app.include_router(cv_enhancement.router)

# ── STATIC FILES ──────────────────────────────────────────────
if not os.path.exists("uploads"):
    os.makedirs("uploads")
if os.path.exists("uploads/profiles"):
    app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")