#!/usr/bin/env python
"""Apply posts and notifications migration manually"""
from sqlalchemy import text
from app.db.database import engine, Base
from app.models import Post, Notification

# Check current migrations
with engine.begin() as conn:
    result = conn.execute(text("SELECT version_num FROM alembic_version ORDER BY version_num"))
    migrations = [row[0] for row in result]
    print(f"Current migrations: {migrations}")

# Create tables if they don't exist
print("\nCreating posts and notifications tables...")
Base.metadata.create_all(engine, [Post.__table__, Notification.__table__])

# Add migration to history
with engine.begin() as conn:
    try:
        conn.execute(text("INSERT INTO alembic_version (version_num) VALUES ('4m2n5o8p1q3r')"))
        print("✓ Added migration 4m2n5o8p1q3r to database")
    except Exception as e:
        print(f"Migration already exists or error: {e}")

# Verify
with engine.begin() as conn:
    result = conn.execute(text("SELECT version_num FROM alembic_version ORDER BY version_num"))
    migrations = [row[0] for row in result]
    print(f"Final migrations: {migrations}")
