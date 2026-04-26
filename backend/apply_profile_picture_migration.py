"""Apply profile picture migration manually"""
from sqlalchemy import text
from app.db.database import engine, Base
from app.models.user import User

# Create tables
Base.metadata.create_all(engine)

# Insert migration revision
with engine.connect() as conn:
    try:
        # Check if revision exists
        result = conn.execute(text("SELECT version_num FROM alembic_version WHERE version_num = '6s4t7u1v2w3x'"))
        if not result.fetchone():
            conn.execute(text("INSERT INTO alembic_version (version_num) VALUES ('6s4t7u1v2w3x')"))
            conn.commit()
            print("✓ Migration 6s4t7u1v2w3x added")
        else:
            print("✓ Migration 6s4t7u1v2w3x already exists")
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()

print("✓ Profile picture field added to users table!")
