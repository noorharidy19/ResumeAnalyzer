
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# 🔥 load .env
load_dotenv()

# 📌 نجيب URL من .env
DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

# 🧪 test connection
if __name__ == "__main__":
    try:
        connection = engine.connect()
        print("✅ Database connected successfully")
    except Exception as e:
        print("❌ Error:", e)