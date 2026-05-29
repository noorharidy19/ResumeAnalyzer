from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.services.auth import get_current_user
from app.services import application as app_service
from app.schemas.job import ApplicationResponse, ApplicationListResponse, ApplicationStatusUpdate

router = APIRouter(prefix="/api/applications", tags=["Applications"])


# ─────────────────────────────────────────────
# Helper guard
# ─────────────────────────────────────────────
def require_company(current_user):
    if getattr(current_user, "role", None) != "company":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only company accounts can perform this action",
        )


# ─────────────────────────────────────────────
# POST /api/applications/apply/{job_id}
# User applies to a job using their saved resume analysis
# ─────────────────────────────────────────────
@router.post("/apply/{job_id}", response_model=ApplicationResponse, status_code=status.HTTP_201_CREATED)
def apply_to_job(
    job_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    # Block companies from applying
    if getattr(current_user, "role", None) == "company":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Company accounts cannot apply to jobs",
        )

    # Fetch the user's latest resume analysis snapshot
    # We look for the most recent saved analysis in the resume_analyses table
    # (adjust the import/model name to match your actual resume analysis model)
    from app.models.resume_analysis import ResumeAnalysis  # adjust import if needed

    latest_analysis = (
        db.query(ResumeAnalysis)
        .filter(ResumeAnalysis.user_id == current_user.id)
        .order_by(ResumeAnalysis.created_at.desc())
        .first()
    )

    if not latest_analysis:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please upload and analyze your CV before applying to jobs",
        )

    resume_snapshot = latest_analysis.phase1  # dict — adjust field name if needed

    return app_service.apply_to_job(
        db=db,
        job_id=job_id,
        user_id=current_user.id,
        resume_snapshot=resume_snapshot,
    )


# ─────────────────────────────────────────────
# GET /api/applications/mine
# Logged-in user sees all their own applications
# ─────────────────────────────────────────────
@router.get("/mine", response_model=list[ApplicationResponse])
def my_applications(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return app_service.get_user_applications(db=db, user_id=current_user.id)


# ─────────────────────────────────────────────
# GET /api/applications/job/{job_id}
# Company sees all applicants for a specific job (sorted by match score)
# ─────────────────────────────────────────────
@router.get("/job/{job_id}", response_model=list[ApplicationListResponse])
def job_applicants(
    job_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    return app_service.get_applications_for_job(db=db, job_id=job_id, company_id=current_user.id)


# ─────────────────────────────────────────────
# GET /api/applications/{application_id}
# Company views full detail of a single application (CV + AI screening)
# ─────────────────────────────────────────────
@router.get("/{application_id}", response_model=ApplicationResponse)
def get_application_detail(
    application_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    return app_service.get_application_detail(
        db=db,
        application_id=application_id,
        company_id=current_user.id,
    )


# ─────────────────────────────────────────────
# PATCH /api/applications/{application_id}/status
# Company accepts / rejects / shortlists
# ─────────────────────────────────────────────
@router.patch("/{application_id}/status", response_model=ApplicationResponse)
def update_status(
    application_id: int,
    data: ApplicationStatusUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    return app_service.update_application_status(
        db=db,
        application_id=application_id,
        company_id=current_user.id,
        data=data,
    )