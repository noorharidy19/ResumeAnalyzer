"""create connections table

Revision ID: 2f9k3j0a1b2c
Revises: 7af7a0ca9739
Create Date: 2026-04-21 14:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2f9k3j0a1b2c'
down_revision = '7af7a0ca9739'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('connections',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('sender_id', sa.String(), nullable=False),
        sa.Column('receiver_id', sa.String(), nullable=False),
        sa.Column('status', sa.Enum('pending', 'accepted', 'rejected', 'blocked', name='connectionstatus'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['receiver_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['sender_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_connections_receiver_id'), 'connections', ['receiver_id'], unique=False)
    op.create_index(op.f('ix_connections_sender_id'), 'connections', ['sender_id'], unique=False)


def downgrade():
    op.drop_index(op.f('ix_connections_sender_id'), table_name='connections')
    op.drop_index(op.f('ix_connections_receiver_id'), table_name='connections')
    op.drop_table('connections')
