"""
Resume Analyzer API
===================
Handles PDF upload and runs Phase 1 (extraction), Phase 2 (job matching), 
and Phase 3 (AI analysis).
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import FileResponse
import os
import json
import tempfile
import traceback
from pathlib import Path
from typing import Optional
from pydantic import BaseModel
from app.models.phase1 import analyze_resume_phase1
from app.models.phase2 import run_phase2
from app.models.phase3 import run_phase3

router = APIRouter(prefix="/api/resume", tags=["resume"])

# Upload directory
UPLOAD_DIR = "uploads/resumes"
os.makedirs(UPLOAD_DIR, exist_ok=True)


class ResumeAnalysisResponse(BaseModel):
    """Full resume analysis response"""
    phase1: dict
    phase2: dict
    phase3: dict
    analysis_id: str
    status: str = "success"


@router.post("/analyze", response_model=ResumeAnalysisResponse)
async def analyze_resume(
    file: UploadFile = File(...),
    top_k: Optional[int] = 3,
    use_external_jobs: Optional[bool] = True,
    location: Optional[str] = "Egypt"
):
    """
    Upload a PDF resume and get complete analysis (Phase 1, 2, 3)
    
    Parameters:
    - file: PDF resume file
    - top_k: Number of job matches to return (default: 3)
    - use_external_jobs: Use SerpAPI for external jobs (default: true)
    - location: Job location (default: Egypt)
    
    Returns:
    {
      "phase1": { extracted resume data },
      "phase2": { job matches and recommendations },
      "phase3": { AI analysis: feedback, career path, interview questions, learning roadmap },
      "analysis_id": "unique_analysis_id",
      "status": "success"
    }
    """
    try:
        # Validate file
        if not file.filename.lower().endswith(".pdf"):
            raise HTTPException(status_code=400, detail="File must be a PDF")

        # Save uploaded file
        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)

        # Run Phase 1: Extract resume data
        print(f"[API] Running Phase 1 on {file.filename}...")
        phase1_result = analyze_resume_phase1(file_path)

        # Run Phase 2: Job matching
        print(f"[API] Running Phase 2...")
        phase2_result = run_phase2(
            phase1_result,
            top_k=top_k,
            use_external_jobs=use_external_jobs,
            location=location
        )

        # Run Phase 3: AI analysis
        print(f"[API] Running Phase 3...")
        phase3_result = run_phase3(phase1_result, phase2_result)

        # Generate analysis ID
        from datetime import datetime
        analysis_id = f"analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        # Save complete analysis
        analysis_output = {
            "analysis_id": analysis_id,
            "filename": file.filename,
            "phase1": phase1_result,
            "phase2": phase2_result,
            "phase3": phase3_result,
        }

        # Save to file
        output_path = os.path.join(UPLOAD_DIR, f"{analysis_id}.json")
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(analysis_output, f, indent=2, ensure_ascii=False)

        print(f"[API] Analysis complete. Saved to {output_path}")

        return ResumeAnalysisResponse(
            phase1=phase1_result,
            phase2=phase2_result,
            phase3=phase3_result,
            analysis_id=analysis_id,
            status="success"
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except FileNotFoundError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        print(f"[API] Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
    finally:
        # Clean up uploaded file (optional - keep for reference)
        pass


@router.get("/history/{analysis_id}")
async def get_analysis(analysis_id: str):
    """
    Retrieve a previously saved analysis by ID
    
    Returns the complete analysis (Phase 1, 2, 3)
    """
    try:
        file_path = os.path.join(UPLOAD_DIR, f"{analysis_id}.json")
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Analysis not found")

        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)

    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Analysis not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving analysis: {str(e)}")


@router.get("/history")
async def list_analyses():
    """
    List all saved analyses
    
    Returns list of analysis metadata
    """
    try:
        analyses = []
        for filename in os.listdir(UPLOAD_DIR):
            if filename.endswith(".json") and filename.startswith("analysis_"):
                file_path = os.path.join(UPLOAD_DIR, filename)
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    analyses.append({
                        "analysis_id": data.get("analysis_id"),
                        "filename": data.get("filename"),
                        "timestamp": filename.replace("analysis_", "").replace(".json", ""),
                    })

        # Sort by timestamp (newest first)
        analyses.sort(key=lambda x: x["timestamp"], reverse=True)
        return {"analyses": analyses, "count": len(analyses)}

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing analyses: {str(e)}")


@router.get("/download/{analysis_id}")
async def download_analysis(analysis_id: str):
    """
    Download analysis as JSON file
    """
    try:
        file_path = os.path.join(UPLOAD_DIR, f"{analysis_id}.json")
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Analysis not found")

        return FileResponse(
            file_path,
            media_type="application/json",
            filename=f"{analysis_id}.json"
        )

    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Analysis not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error downloading analysis: {str(e)}")


@router.delete("/history/{analysis_id}")
async def delete_analysis(analysis_id: str):
    """
    Delete a saved analysis
    """
    try:
        file_path = os.path.join(UPLOAD_DIR, f"{analysis_id}.json")
        if not os.path.exists(file_path):
            raise HTTPException(status_code=404, detail="Analysis not found")

        os.remove(file_path)
        return {"status": "success", "message": f"Analysis {analysis_id} deleted"}

    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Analysis not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error deleting analysis: {str(e)}")
