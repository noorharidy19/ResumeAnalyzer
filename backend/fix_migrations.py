from sqlalchemy import text
from app.db.database import Base, engine
from app.models import Message, Connection, User

print('Creating all tables...')
Base.metadata.create_all(bind=engine)
print('✓ Tables created')

# Update migration history
with engine.connect() as conn:
    with conn.begin():
        # Insert the messages migration as completed
        conn.execute(text("INSERT INTO alembic_version (version_num) VALUES ('3k9f1a2b4c5d') ON CONFLICT DO NOTHING"))
    
    # Verify
    result = conn.execute(text('SELECT version_num FROM alembic_version ORDER BY version_num'))
    versions = [row[0] for row in result]
    print(f'✓ Migration history: {versions}')
