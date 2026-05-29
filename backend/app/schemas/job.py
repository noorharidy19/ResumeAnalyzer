from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime
from enum import Enum


# ─────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────
class JobStatusEnum(str, Enum):
    open   = "open"
    closed = "closed"


class ApplicationStatusEnum(str, Enum):
    pending     = "pending"
    shortlisted = "shortlisted"
    accepted    = "accepted"
    rejected    = "rejected"


class VerdictEnum(str, Enum):
    good_fit    = "good_fit"
    average_fit = "average_fit"
    weak_fit    = "weak_fit"


# ─────────────────────────────────────────────
# Job schemas
# ─────────────────────────────────────────────
class JobCreate(BaseModel):
    title:        str            = Field(..., min_length=3, max_length=255)
    description:  str            = Field(..., min_length=10)
    requirements: List[str]      = Field(..., description="List of required/preferred skills or qualifications")
    location:     Optional[str]  = None
    job_type:     Optional[str]  = None   # Full-time, Part-time, Remote, etc.


class JobUpdate(BaseModel):
    title:        Optional[str]       = None
    description:  Optional[str]       = None
    requirements: Optional[List[str]] = None
    location:     Optional[str]       = None
    job_type:     Optional[str]       = None
    status:       Optional[JobStatusEnum] = None


class CompanyBrief(BaseModel):
    id:   int
    name: str

    class Config:
        from_attributes = True


class JobResponse(BaseModel):
    id:           int
    title:        str
    description:  str
    requirements: List[str]
    location:     Optional[str]
    job_type:     Optional[str]
    status:       JobStatusEnum
    created_at:   datetime
    company:      CompanyBrief

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Application schemas
# ─────────────────────────────────────────────
class ApplicationCreate(BaseModel):
    """No body needed — job_id comes from the URL, user from the token."""
    pass


class ApplicationStatusUpdate(BaseModel):
    status: ApplicationStatusEnum


class ApplicantBrief(BaseModel):
    id:    int
    name:  str
    email: str

    class Config:
        from_attributes = True


class AIScreeningResult(BaseModel):
    match_score:        int
    verdict:            VerdictEnum
    matched_skills:     List[str]
    missing_skills:     List[str]
    matched_experience: str
    weak_points:        List[str]
    summary:            str


class ApplicationResponse(BaseModel):
    id:              int
    job_id:          int
    user_id:         int
    match_score:     Optional[float]
    verdict:         Optional[VerdictEnum]
    ai_screening:    Optional[Any]           # full AIScreeningResult dict
    status:          ApplicationStatusEnum
    applied_at:      datetime
    reviewed_at:     Optional[datetime]
    applicant:       ApplicantBrief
    job:             Optional[JobResponse] = None

    class Config:
        from_attributes = True


class ApplicationListResponse(BaseModel):
    """Lightweight version for the company's applicant list."""
    id:          int
    match_score: Optional[float]
    verdict:     Optional[VerdictEnum]
    status:      ApplicationStatusEnum
    applied_at:  datetime
    applicant:   ApplicantBrief

    class Config:
        from_attributes = True