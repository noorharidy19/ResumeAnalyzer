import json
import os
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from app.services.cv_enhancement import generate_pdf
from app.services.cv_enhancement import enhance_cv

router = APIRouter(tags=["CV Enhancement"])

UPLOAD_DIR = "uploads/resumes"
EXPORT_DIR = "uploads/cv_exports"
os.makedirs(EXPORT_DIR, exist_ok=True)


@router.get("/{analysis_id}")
def get_enhancement(analysis_id: str):
    """
    Fetch saved Phase 4 enhancement. Returns 404 while still processing (Flutter polls).
    """
    path = os.path.join(UPLOAD_DIR, f"{analysis_id}_enhancement.json")
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Enhancement not ready yet.")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


@router.post("/enhance/{analysis_id}")
def trigger_enhancement(analysis_id: str, target_job: str | None = None):
    """
    Synchronously run Phase 4 for a past analysis (re-run from history).
    Reads the existing analysis JSON, runs Phase 4, saves result.
    """
    

    analysis_path = os.path.join(UPLOAD_DIR, f"{analysis_id}.json")
    if not os.path.exists(analysis_path):
        raise HTTPException(status_code=404, detail="Analysis not found.")

    with open(analysis_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    try:
        result = enhance_cv(
            analysis_id=analysis_id,
            phase1_data=data["phase1"],
            phase2_data=data["phase2"],
            target_job=target_job,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Enhancement failed: {e}")


@router.get("/{analysis_id}/export/pdf")
def export_pdf(analysis_id: str):
    """
    Generate (or return cached) PDF of the enhanced CV.
    """
    enhancement_path = os.path.join(UPLOAD_DIR, f"{analysis_id}_enhancement.json")
    if not os.path.exists(enhancement_path):
        raise HTTPException(status_code=404, detail="Enhancement not ready yet.")

    with open(enhancement_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    filepath = os.path.join(EXPORT_DIR, f"{analysis_id}.pdf")

    # Only regenerate if it doesn't already exist
    if not os.path.exists(filepath):
        
        generate_pdf(data["phase4"], filepath)

    return FileResponse(
        path=filepath,
        media_type="application/pdf",
        filename=f"enhanced_cv_{analysis_id}.pdf",
        headers={"Content-Disposition": f"attachment; filename=enhanced_cv_{analysis_id}.pdf"},
    )