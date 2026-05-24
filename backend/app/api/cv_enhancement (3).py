import json
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.services.auth import get_current_user
from app.models.user import User
from app.schemas.cv_enhancement import EnhancementRequest, EnhancementResponse
import app.services.cv_enhancement as svc

router = APIRouter(tags=["CV Enhancement"])


# ── Helper: load phase data from an existing analysis ────────────────────────
def _get_analysis_phases(analysis_id: int, db: Session) -> tuple[dict, dict]:
    """
    Fetch phase1_result and phase2_result JSON from the resume_analyses table.
    Adjust the import/query to match your actual ResumeAnalysis model column names.
    """
    from app.models.resume_analysis import ResumeAnalysis   # adjust path if needed

    analysis = db.query(ResumeAnalysis).filter(ResumeAnalysis.id == analysis_id).first()
    if not analysis:
        raise HTTPException(status_code=404, detail="Analysis not found")

    try:
        phase1 = json.loads(analysis.phase1_result)
        phase2 = json.loads(analysis.phase2_result)
    except Exception:
        raise HTTPException(status_code=422, detail="Could not parse phase data from analysis")

    return phase1, phase2


# ── POST /api/cv/enhance ──────────────────────────────────────────────────────
@router.post("/enhance", response_model=EnhancementResponse, status_code=status.HTTP_202_ACCEPTED)
def trigger_enhancement(
    body: EnhancementRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Trigger Phase 4 CV enhancement.
    Runs as a BackgroundTask — returns 202 immediately.
    Flutter should poll GET /api/cv/{analysis_id} until it gets a 200.

    If you prefer a synchronous response (simpler Flutter logic), remove
    background_tasks and call svc.enhance_cv() directly, then return the result.
    """
    phase1, phase2 = _get_analysis_phases(body.analysis_id, db)

    # Kick off in the background so the HTTP response returns immediately
    background_tasks.add_task(
        svc.enhance_cv,
        db=db,
        analysis_id=body.analysis_id,
        user_id=current_user.id,
        phase1_data=phase1,
        phase2_data=phase2,
        target_job=body.target_job,
    )

    # Return a lightweight placeholder — Flutter polls until the real record exists
    return {
        "id": -1,
        "analysis_id": body.analysis_id,
        "user_id": current_user.id,
        "target_job": body.target_job,
        "rewritten_sections": {"summary": "", "experience": []},
        "certificates": [],
        "skill_gaps": [],
        "export_path": None,
        "created_at": "",
    }


# ── GET /api/cv/{analysis_id} ─────────────────────────────────────────────────
@router.get("/{analysis_id}", response_model=EnhancementResponse)
def get_enhancement(
    analysis_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Fetch the most recent CV enhancement for the given analysis.
    Returns 404 while Phase 4 is still running (Flutter polls this endpoint).
    """
    result = svc.get_enhancement(db, analysis_id=analysis_id, user_id=current_user.id)
    if not result:
        raise HTTPException(
            status_code=404,
            detail="Enhancement not ready yet. Please try again in a moment.",
        )
    return result


# ── GET /api/cv/{analysis_id}/export/pdf ──────────────────────────────────────
@router.get("/{analysis_id}/export/pdf")
def export_pdf(
    analysis_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Generate (or return cached) PDF of the enhanced CV.
    Returns the file as an attachment download.
    """
    try:
        filepath = svc.export_cv_pdf(db, analysis_id=analysis_id, user_id=current_user.id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {e}")

    return FileResponse(
        path=filepath,
        media_type="application/pdf",
        filename=f"enhanced_cv_{analysis_id}.pdf",
        headers={"Content-Disposition": f"attachment; filename=enhanced_cv_{analysis_id}.pdf"},
    )
