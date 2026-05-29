from sqlalchemy import Column, Integer, String, Text, Float, ForeignKey, Enum, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

from app.db.database import Base


class JobStatus(str, enum.Enum):
    open   = "open"
    closed = "closed"


class ApplicationStatus(str, enum.Enum):
    pending     = "pending"
    shortlisted = "shortlisted"
    accepted    = "accepted"
    rejected    = "rejected"


class Verdict(str, enum.Enum):
    good_fit    = "good_fit"
    average_fit = "average_fit"
    weak_fit    = "weak_fit"


# ─────────────────────────────────────────────
# Job table  (created by a company user)
# ─────────────────────────────────────────────
class Job(Base):
    __tablename__ = "jobs"

    id           = Column(Integer, primary_key=True, index=True)
    company_id   = Column(Integer, ForeignKey("users.id"), nullable=False)
    title        = Column(String(255), nullable=False)
    description  = Column(Text, nullable=False)
    requirements = Column(JSON, nullable=False, default=list)   # list[str]
    location     = Column(String(255), nullable=True)
    job_type     = Column(String(100), nullable=True)           # Full-time / Part-time / Remote
    status       = Column(Enum(JobStatus), default=JobStatus.open, nullable=False)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
    updated_at   = Column(DateTime(timezone=True), onupdate=func.now())

    # relationships
    company      = relationship("User", back_populates="posted_jobs")
    applications = relationship("Application", back_populates="job", cascade="all, delete-orphan")


# ─────────────────────────────────────────────
# Application table  (user applies to a job)
# ─────────────────────────────────────────────
class Application(Base):
    __tablename__ = "applications"

    id                 = Column(Integer, primary_key=True, index=True)
    job_id             = Column(Integer, ForeignKey("jobs.id"), nullable=False)
    user_id            = Column(Integer, ForeignKey("users.id"), nullable=False)

    # snapshot of the applicant's Phase 1 extraction at apply-time
    resume_snapshot    = Column(JSON, nullable=True)

    # AI screening results (from phase_jobs.py)
    match_score        = Column(Float, nullable=True)
    verdict            = Column(Enum(Verdict), nullable=True)
    ai_screening       = Column(JSON, nullable=True)            # full JSON from run_job_screening()

    status             = Column(Enum(ApplicationStatus), default=ApplicationStatus.pending, nullable=False)
    applied_at         = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at        = Column(DateTime(timezone=True), nullable=True)

    # relationships
    job                = relationship("Job", back_populates="applications")
    applicant          = relationship("User", back_populates="applications")