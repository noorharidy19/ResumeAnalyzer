from fastapi import FastAPI
from app.api import auth, connections, users, messages, posts, notifications

app = FastAPI()

app.include_router(auth.router)
app.include_router(connections.router)
app.include_router(users.router)
app.include_router(messages.router)
app.include_router(posts.router)
app.include_router(notifications.router)
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)