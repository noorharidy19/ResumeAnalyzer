import json
import os
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional
from app.services.cv_enhancement import generate_pdf, enhance_cv

router = APIRouter(prefix="/api/cv", tags=["CV Enhancement"])  # ✅ add prefix

UPLOAD_DIR = "uploads/resumes"
EXPORT_DIR = "uploads/cv_exports"
os.makedirs(EXPORT_DIR, exist_ok=True)


class EnhanceRequest(BaseModel):           # ✅ match Dart's JSON body
    analysis_id: str
    target_job: Optional[str] = None


@router.post("/enhance")                   # ✅ POST /api/cv/enhance
def trigger_enhancement(req: EnhanceRequest):
    analysis_path = os.path.join(UPLOAD_DIR, f"{req.analysis_id}.json")
    if not os.path.exists(analysis_path):
        raise HTTPException(status_code=404, detail="Analysis not found.")

    with open(analysis_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    try:
        result = enhance_cv(
            analysis_id=req.analysis_id,
            phase1_data=data["phase1"],
            phase2_data=data["phase2"],
            target_job=req.target_job,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Enhancement failed: {e}")


@router.get("/{analysis_id}/export/pdf")   # ✅ GET /api/cv/{id}/export/pdf
def export_pdf(analysis_id: str):
    enhancement_path = os.path.join(UPLOAD_DIR, f"{analysis_id}_enhancement.json")
    if not os.path.exists(enhancement_path):
        raise HTTPException(status_code=404, detail="Enhancement not ready yet.")

    with open(enhancement_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    filepath = os.path.join(EXPORT_DIR, f"{analysis_id}.pdf")
    if not os.path.exists(filepath):
        generate_pdf(data["phase4"], filepath)

    return FileResponse(
        path=filepath,
        media_type="application/pdf",
        filename=f"enhanced_cv_{analysis_id}.pdf",
        headers={"Content-Disposition": f"attachment; filename=enhanced_cv_{analysis_id}.pdf"},
    )


@router.get("/{analysis_id}")              # ✅ GET /api/cv/{id}  — keep LAST to avoid shadowing
def get_enhancement(analysis_id: str):
    path = os.path.join(UPLOAD_DIR, f"{analysis_id}_enhancement.json")
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Enhancement not ready yet.")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)