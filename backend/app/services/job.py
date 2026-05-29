from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.job import Job, JobStatus
from app.schemas.job import JobCreate, JobUpdate


# ─────────────────────────────────────────────
# Create
# ─────────────────────────────────────────────
def create_job(db: Session, company_id: int, data: JobCreate) -> Job:
    job = Job(
        company_id   = company_id,
        title        = data.title,
        description  = data.description,
        requirements = data.requirements,
        location     = data.location,
        job_type     = data.job_type,
        status       = JobStatus.open,
    )
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


# ─────────────────────────────────────────────
# Read
# ─────────────────────────────────────────────
def get_all_jobs(db: Session, skip: int = 0, limit: int = 50) -> list[Job]:
    return (
        db.query(Job)
        .filter(Job.status == JobStatus.open)
        .order_by(Job.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_job_by_id(db: Session, job_id: int) -> Job:
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return job


def get_company_jobs(db: Session, company_id: int) -> list[Job]:
    return (
        db.query(Job)
        .filter(Job.company_id == company_id)
        .order_by(Job.created_at.desc())
        .all()
    )


# ─────────────────────────────────────────────
# Update
# ─────────────────────────────────────────────
def update_job(db: Session, job_id: int, company_id: int, data: JobUpdate) -> Job:
    job = get_job_by_id(db, job_id)
    if job.company_id != company_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your job post")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(job, field, value)

    db.commit()
    db.refresh(job)
    return job


# ─────────────────────────────────────────────
# Delete
# ─────────────────────────────────────────────
def delete_job(db: Session, job_id: int, company_id: int) -> None:
    job = get_job_by_id(db, job_id)
    if job.company_id != company_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your job post")
    db.delete(job)
    db.commit()