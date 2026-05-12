#!/usr/bin/env python3
from app.db.database import SessionLocal, engine
from sqlalchemy import text, inspect

db = SessionLocal()
inspector = inspect(engine)
tables = inspector.get_table_names()

print("Existing tables:", tables)

# Check if engagement tables exist
if 'post_likes' in tables:
    print("✓ post_likes table exists")
else:
    print("✗ post_likes table NOT found - creating...")

if 'comments' in tables:
    print("✓ comments table exists")
else:
    print("✗ comments table NOT found - creating...")

if 'reposts' in tables:
    print("✓ reposts table exists")
else:
    print("✗ reposts table NOT found - creating...")

# Check if posts has the new columns
posts_columns = [col['name'] for col in inspector.get_columns('posts')]
print("\nPosts columns:", posts_columns)

if 'comments_count' in posts_columns:
    print("✓ comments_count column exists")
else:
    print("✗ comments_count column NOT found - adding...")

if 'reposts_count' in posts_columns:
    print("✓ reposts_count column exists")
else:
    print("✗ reposts_count column NOT found - adding...")

# Try to create the tables
try:
    with engine.begin() as conn:
        # Add columns to posts if they don't exist
        if 'comments_count' not in posts_columns:
            conn.execute(text('ALTER TABLE posts ADD COLUMN comments_count INTEGER DEFAULT 0 NOT NULL'))
            print("\n✓ Added comments_count to posts")
        
        if 'reposts_count' not in posts_columns:
            conn.execute(text('ALTER TABLE posts ADD COLUMN reposts_count INTEGER DEFAULT 0 NOT NULL'))
            print("✓ Added reposts_count to posts")
        
        # Create post_likes table
        if 'post_likes' not in tables:
            conn.execute(text('''
                CREATE TABLE post_likes (
                    id VARCHAR NOT NULL PRIMARY KEY,
                    post_id VARCHAR NOT NULL,
                    user_id VARCHAR NOT NULL,
                    created_at TIMESTAMP NOT NULL,
                    FOREIGN KEY (post_id) REFERENCES posts(id),
                    FOREIGN KEY (user_id) REFERENCES users(id)
                )
            '''))
            conn.execute(text('CREATE INDEX ix_post_likes_post_id ON post_likes(post_id)'))
            conn.execute(text('CREATE INDEX ix_post_likes_user_id ON post_likes(user_id)'))
            print("\n✓ Created post_likes table")
        
        # Create comments table
        if 'comments' not in tables:
            conn.execute(text('''
                CREATE TABLE comments (
                    id VARCHAR NOT NULL PRIMARY KEY,
                    post_id VARCHAR NOT NULL,
                    creator_id VARCHAR NOT NULL,
                    content VARCHAR NOT NULL,
                    created_at TIMESTAMP NOT NULL,
                    updated_at TIMESTAMP NOT NULL,
                    FOREIGN KEY (post_id) REFERENCES posts(id),
                    FOREIGN KEY (creator_id) REFERENCES users(id)
                )
            '''))
            conn.execute(text('CREATE INDEX ix_comments_post_id ON comments(post_id)'))
            conn.execute(text('CREATE INDEX ix_comments_creator_id ON comments(creator_id)'))
            conn.execute(text('CREATE INDEX ix_comments_created_at ON comments(created_at)'))
            print("✓ Created comments table")
        
        # Create reposts table
        if 'reposts' not in tables:
            conn.execute(text('''
                CREATE TABLE reposts (
                    id VARCHAR NOT NULL PRIMARY KEY,
                    post_id VARCHAR NOT NULL,
                    user_id VARCHAR NOT NULL,
                    created_at TIMESTAMP NOT NULL,
                    FOREIGN KEY (post_id) REFERENCES posts(id),
                    FOREIGN KEY (user_id) REFERENCES users(id)
                )
            '''))
            conn.execute(text('CREATE INDEX ix_reposts_post_id ON reposts(post_id)'))
            conn.execute(text('CREATE INDEX ix_reposts_user_id ON reposts(user_id)'))
            conn.execute(text('CREATE INDEX ix_reposts_created_at ON reposts(created_at)'))
            print("✓ Created reposts table")
        
        print("\n✅ All engagement feature tables are ready!")

except Exception as e:
    print(f"\n✗ Error: {e}")
    print("Some tables may already exist. This is okay.")
