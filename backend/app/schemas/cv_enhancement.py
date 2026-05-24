from __future__ import annotations
from typing import Literal
from pydantic import BaseModel, HttpUrl


# ── Request ──────────────────────────────────────────────────────────────────

class EnhancementRequest(BaseModel):
    analysis_id: int
    target_job: str | None = None   # Optional; AI infers from Phase 2 if omitted


# ── Sub-models ────────────────────────────────────────────────────────────────

class ExperienceBullet(BaseModel):
    original: str
    improved: str


class RewrittenSections(BaseModel):
    summary: str
    experience: list[ExperienceBullet]


class CertificateItem(BaseModel):
    name: str
    provider: str
    url: str                        # Kept as str — URLs from AI may not always parse as HttpUrl
    why: str
    priority: int                   # 1 = highest priority


class SkillGapItem(BaseModel):
    skill: str
    importance: Literal["high", "medium", "low"]
    how_to_acquire: str


# ── Response ──────────────────────────────────────────────────────────────────

class EnhancementResponse(BaseModel):
    id: int
    analysis_id: int
    user_id: int
    target_job: str | None
    rewritten_sections: RewrittenSections
    certificates: list[CertificateItem]
    skill_gaps: list[SkillGapItem]
    export_path: str | None         # Populated after PDF is generated
    created_at: str

    class Config:
        from_attributes = True
