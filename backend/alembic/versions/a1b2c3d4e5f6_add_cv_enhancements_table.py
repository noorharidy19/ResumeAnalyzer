"""add cv_enhancements table

Revision ID: a1b2c3d4e5f6
Revises: <put your last revision id here>
Create Date: 2025-01-01 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = "a1b2c3d4e5f6"
down_revision = None   # ← Replace with your actual latest revision ID
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "cv_enhancements",
        sa.Column("id", sa.Integer(), primary_key=True, index=True),
        sa.Column(
            "analysis_id",
            sa.Integer(),
            sa.ForeignKey("resume_analyses.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("target_job", sa.String(255), nullable=True),
        sa.Column("phase4_json", sa.Text(), nullable=False),
        sa.Column("export_path", sa.String(512), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("cv_enhancements")
