#!/usr/bin/env python3
"""Verify engagement feature columns and tables"""
from app.db.database import SessionLocal, engine
from sqlalchemy import text, inspect

# Get database info
inspector = inspect(engine)

# Check posts table
print("✓ Checking posts table structure:")
posts_columns = inspector.get_columns('posts')
for col in posts_columns:
    print(f"  - {col['name']}: {col['type']}")

# Verify engagement tables
tables = inspector.get_table_names()
print("\n✓ Engagement tables:")
for table in ['post_likes', 'comments', 'reposts']:
    if table in tables:
        print(f"  ✓ {table} exists")
    else:
        print(f"  ✗ {table} MISSING")

# Try querying posts to see their structure
try:
    db = SessionLocal()
    result = db.query(text("SELECT * FROM posts LIMIT 1")).first()
    if result:
        print("\n✓ Sample post from database:")
        print(f"  Columns: {result}")
    else:
        print("\n⚠ No posts in database yet")
    db.close()
except Exception as e:
    print(f"\n✗ Error querying posts: {e}")
