"""Add comments_count and reposts_count to posts

Revision ID: add_comments_reposts_columns
Revises: 4m2n5o8p1q3r
Create Date: 2026-05-17 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_comments_reposts_columns'
down_revision = '4m2n5o8p1q3r'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('posts', sa.Column('comments_count', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('posts', sa.Column('reposts_count', sa.Integer(), nullable=False, server_default='0'))


def downgrade() -> None:
    op.drop_column('posts', 'reposts_count')
    op.drop_column('posts', 'comments_count')
    