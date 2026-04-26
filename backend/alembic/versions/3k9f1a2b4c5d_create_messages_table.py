"""create messages table

Revision ID: 3k9f1a2b4c5d
Revises: 2f9k3j0a1b2c
Create Date: 2026-04-25 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '3k9f1a2b4c5d'
down_revision = '2f9k3j0a1b2c'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('messages',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('sender_id', sa.String(), nullable=False),
        sa.Column('receiver_id', sa.String(), nullable=False),
        sa.Column('connection_id', sa.String(), nullable=False),
        sa.Column('content', sa.String(), nullable=False),
        sa.Column('is_read', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['connection_id'], ['connections.id'], ),
        sa.ForeignKeyConstraint(['receiver_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['sender_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_messages_connection_id'), 'messages', ['connection_id'], unique=False)
    op.create_index(op.f('ix_messages_created_at'), 'messages', ['created_at'], unique=False)
    op.create_index(op.f('ix_messages_receiver_id'), 'messages', ['receiver_id'], unique=False)
    op.create_index(op.f('ix_messages_sender_id'), 'messages', ['sender_id'], unique=False)


def downgrade():
    op.drop_index(op.f('ix_messages_sender_id'), table_name='messages')
    op.drop_index(op.f('ix_messages_receiver_id'), table_name='messages')
    op.drop_index(op.f('ix_messages_created_at'), table_name='messages')
    op.drop_index(op.f('ix_messages_connection_id'), table_name='messages')
    op.drop_table('messages')
