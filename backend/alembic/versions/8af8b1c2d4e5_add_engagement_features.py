"""Add engagement features - likes, comments, reposts

Revision ID: 8af8b1c2d4e5
Revises: 4m2n5o8p1q3r
Create Date: 2026-05-09 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '8af8b1c2d4e5'
down_revision = '4m2n5o8p1q3r'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new columns to posts table
    op.add_column('posts', sa.Column('comments_count', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('posts', sa.Column('reposts_count', sa.Integer(), nullable=False, server_default='0'))
    
    # Create post_likes table
    op.create_table(
        'post_likes',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('post_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_post_likes_post_id'), 'post_likes', ['post_id'], unique=False)
    op.create_index(op.f('ix_post_likes_user_id'), 'post_likes', ['user_id'], unique=False)
    
    # Create comments table
    op.create_table(
        'comments',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('post_id', sa.String(), nullable=False),
        sa.Column('creator_id', sa.String(), nullable=False),
        sa.Column('content', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['creator_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_comments_creator_id'), 'comments', ['creator_id'], unique=False)
    op.create_index(op.f('ix_comments_post_id'), 'comments', ['post_id'], unique=False)
    op.create_index(op.f('ix_comments_created_at'), 'comments', ['created_at'], unique=False)
    
    # Create reposts table
    op.create_table(
        'reposts',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('post_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_reposts_post_id'), 'reposts', ['post_id'], unique=False)
    op.create_index(op.f('ix_reposts_user_id'), 'reposts', ['user_id'], unique=False)
    op.create_index(op.f('ix_reposts_created_at'), 'reposts', ['created_at'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_reposts_created_at'), table_name='reposts')
    op.drop_index(op.f('ix_reposts_user_id'), table_name='reposts')
    op.drop_index(op.f('ix_reposts_post_id'), table_name='reposts')
    op.drop_table('reposts')
    
    op.drop_index(op.f('ix_comments_created_at'), table_name='comments')
    op.drop_index(op.f('ix_comments_post_id'), table_name='comments')
    op.drop_index(op.f('ix_comments_creator_id'), table_name='comments')
    op.drop_table('comments')
    
    op.drop_index(op.f('ix_post_likes_user_id'), table_name='post_likes')
    op.drop_index(op.f('ix_post_likes_post_id'), table_name='post_likes')
    op.drop_table('post_likes')
    
    op.drop_column('posts', 'reposts_count')
    op.drop_column('posts', 'comments_count')
