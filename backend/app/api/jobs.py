from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.services.auth import get_current_user
from app.services import job as job_service
from app.schemas.job import JobCreate, JobUpdate, JobResponse

router = APIRouter(prefix="/api/jobs", tags=["Jobs"])


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
# POST /api/jobs/create  — company only
# ─────────────────────────────────────────────
@router.post("/create", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def create_job(
    data: JobCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    return job_service.create_job(db=db, company_id=current_user.id, data=data)


# ─────────────────────────────────────────────
# GET /api/jobs/  — all open jobs (any logged-in user)
# ─────────────────────────────────────────────
@router.get("/", response_model=list[JobResponse])
def list_jobs(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return job_service.get_all_jobs(db=db, skip=skip, limit=limit)


# ─────────────────────────────────────────────
# GET /api/jobs/my-posts  — company's own postings
# ─────────────────────────────────────────────
@router.get("/my-posts", response_model=list[JobResponse])
def my_job_posts(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    return job_service.get_company_jobs(db=db, company_id=current_user.id)


# ─────────────────────────────────────────────
# GET /api/jobs/{job_id}  — single job detail
# ─────────────────────────────────────────────
@router.get("/{job_id}", response_model=JobResponse)
def get_job(
    job_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return job_service.get_job_by_id(db=db, job_id=job_id)


# ─────────────────────────────────────────────
# PATCH /api/jobs/{job_id}  — update (company only)
# ─────────────────────────────────────────────
@router.patch("/{job_id}", response_model=JobResponse)
def update_job(
    job_id: int,
    data: JobUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    return job_service.update_job(db=db, job_id=job_id, company_id=current_user.id, data=data)


# ─────────────────────────────────────────────
# DELETE /api/jobs/{job_id}  — company only
# ─────────────────────────────────────────────
@router.delete("/{job_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_job(
    job_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    require_company(current_user)
    job_service.delete_job(db=db, job_id=job_id, company_id=current_user.id)