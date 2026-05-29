from sqlalchemy.orm import Session
from sqlalchemy.sql import func
from fastapi import HTTPException, status
from datetime import datetime, timezone

from app.models.job import Job, Application, ApplicationStatus, Verdict, JobStatus
from app.models.phase_jobs import run_job_screening
from app.schemas.job import ApplicationStatusUpdate


# ─────────────────────────────────────────────
# Apply to a job
# ─────────────────────────────────────────────
def apply_to_job(db: Session, job_id: int, user_id: int, resume_snapshot: dict) -> Application:
    """
    Creates an application and runs AI screening.

    resume_snapshot: the Phase 1 dict already stored for this user.
    If the user has never uploaded a CV, the caller should reject with 400.
    """
    # Verify job exists and is open
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    if job.status != JobStatus.open:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This job is no longer accepting applications")

    # Prevent duplicate applications
    existing = db.query(Application).filter(
        Application.job_id  == job_id,
        Application.user_id == user_id,
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="You have already applied to this job")

    # Run AI screening
    job_post = {
        "title":        job.title,
        "description":  job.description,
        "requirements": job.requirements,
        "location":     job.location,
        "job_type":     job.job_type,
    }

    try:
        screening = run_job_screening(phase1_data=resume_snapshot, job_post=job_post)
    except Exception as e:
        # Don't block the application if AI fails — save without screening
        print(f"[ApplicationService] AI screening failed: {e}")
        screening = None

    # Build the application record
    verdict_val = None
    score_val   = None

    if screening:
        score_val   = screening.get("match_score")
        raw_verdict = screening.get("verdict")
        try:
            verdict_val = Verdict(raw_verdict)
        except (ValueError, KeyError):
            verdict_val = None

    application = Application(
        job_id          = job_id,
        user_id         = user_id,
        resume_snapshot = resume_snapshot,
        match_score     = score_val,
        verdict         = verdict_val,
        ai_screening    = screening,
        status          = ApplicationStatus.pending,
    )

    db.add(application)
    db.commit()
    db.refresh(application)
    return application


# ─────────────────────────────────────────────
# Read
# ─────────────────────────────────────────────
def get_applications_for_job(db: Session, job_id: int, company_id: int) -> list[Application]:
    """Returns all applicants for a job — company use only."""
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    if job.company_id != company_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your job post")

    return (
        db.query(Application)
        .filter(Application.job_id == job_id)
        .order_by(Application.match_score.desc().nullslast(), Application.applied_at.asc())
        .all()
    )


def get_application_detail(db: Session, application_id: int, company_id: int) -> Application:
    """Full application detail for a company viewer."""
    app = db.query(Application).filter(Application.id == application_id).first()
    if not app:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
    if app.job.company_id != company_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your job post")
    return app


def get_user_applications(db: Session, user_id: int) -> list[Application]:
    """Returns all applications the current user has submitted."""
    return (
        db.query(Application)
        .filter(Application.user_id == user_id)
        .order_by(Application.applied_at.desc())
        .all()
    )


# ─────────────────────────────────────────────
# Update status  (company only)
# ─────────────────────────────────────────────
def update_application_status(
    db: Session,
    application_id: int,
    company_id: int,
    data: ApplicationStatusUpdate,
) -> Application:
    app = db.query(Application).filter(Application.id == application_id).first()
    if not app:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
    if app.job.company_id != company_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your job post")

    app.status      = ApplicationStatus(data.status.value)
    app.reviewed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(app)
    return app