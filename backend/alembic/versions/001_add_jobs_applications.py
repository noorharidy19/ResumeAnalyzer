"""add jobs and applications tables

Revision ID: 001_jobs_applications
Revises: <put your latest revision id here>
Create Date: 2025-01-01 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '001_jobs_applications'
down_revision = "4m2n5o8p1q3r"      # ← replace with your current head revision id
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── jobs ──────────────────────────────────────────
    op.create_table(
        'jobs',
        sa.Column('id',           sa.Integer(),     nullable=False),
        sa.Column('company_id',   sa.Integer(),     nullable=False),
        sa.Column('title',        sa.String(255),   nullable=False),
        sa.Column('description',  sa.Text(),        nullable=False),
        sa.Column('requirements', sa.JSON(),        nullable=False),
        sa.Column('location',     sa.String(255),   nullable=True),
        sa.Column('job_type',     sa.String(100),   nullable=True),
        sa.Column('status',
                  sa.Enum('open', 'closed', name='jobstatus'),
                  nullable=False,
                  server_default='open'),
        sa.Column('created_at',   sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('updated_at',   sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['company_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_jobs_id',         'jobs', ['id'],         unique=False)
    op.create_index('ix_jobs_company_id', 'jobs', ['company_id'], unique=False)

    # ── applications ──────────────────────────────────
    op.create_table(
        'applications',
        sa.Column('id',              sa.Integer(),   nullable=False),
        sa.Column('job_id',          sa.Integer(),   nullable=False),
        sa.Column('user_id',         sa.Integer(),   nullable=False),
        sa.Column('resume_snapshot', sa.JSON(),      nullable=True),
        sa.Column('match_score',     sa.Float(),     nullable=True),
        sa.Column('verdict',
                  sa.Enum('good_fit', 'average_fit', 'weak_fit', name='verdict'),
                  nullable=True),
        sa.Column('ai_screening',    sa.JSON(),      nullable=True),
        sa.Column('status',
                  sa.Enum('pending', 'shortlisted', 'accepted', 'rejected', name='applicationstatus'),
                  nullable=False,
                  server_default='pending'),
        sa.Column('applied_at',   sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('reviewed_at',  sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['job_id'],  ['jobs.id'],  ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('job_id', 'user_id', name='uq_application_job_user'),
    )
    op.create_index('ix_applications_id',      'applications', ['id'],      unique=False)
    op.create_index('ix_applications_job_id',  'applications', ['job_id'],  unique=False)
    op.create_index('ix_applications_user_id', 'applications', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_applications_user_id', table_name='applications')
    op.drop_index('ix_applications_job_id',  table_name='applications')
    op.drop_index('ix_applications_id',      table_name='applications')
    op.drop_table('applications')

    op.drop_index('ix_jobs_company_id', table_name='jobs')
    op.drop_index('ix_jobs_id',         table_name='jobs')
    op.drop_table('jobs')

    sa.Enum(name='applicationstatus').drop(op.get_bind(), checkfirst=True)
    sa.Enum(name='verdict').drop(op.get_bind(),           checkfirst=True)
    sa.Enum(name='jobstatus').drop(op.get_bind(),         checkfirst=True)