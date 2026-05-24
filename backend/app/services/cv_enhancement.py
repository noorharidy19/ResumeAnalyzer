import json
import os
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.cv_enhancement import CVEnhancement
from app.models.phase4 import run_phase4
from app.schemas.cv_enhancement import EnhancementResponse, RewrittenSections, CertificateItem, SkillGapItem, ExperienceBullet


# ── Helpers ───────────────────────────────────────────────────────────────────

def _parse_phase4_json(raw_json: str) -> dict:
    return json.loads(raw_json)


def _row_to_response(row: CVEnhancement) -> EnhancementResponse:
    data = _parse_phase4_json(row.phase4_json)

    rewritten = RewrittenSections(
        summary=data["rewritten_sections"]["summary"],
        experience=[
            ExperienceBullet(**b) for b in data["rewritten_sections"]["experience"]
        ],
    )
    certificates = [CertificateItem(**c) for c in data["certificates"]]
    skill_gaps = [SkillGapItem(**s) for s in data["skill_gaps"]]

    return EnhancementResponse(
        id=row.id,
        analysis_id=row.analysis_id,
        user_id=row.user_id,
        target_job=row.target_job,
        rewritten_sections=rewritten,
        certificates=certificates,
        skill_gaps=skill_gaps,
        export_path=row.export_path,
        created_at=row.created_at.isoformat(),
    )


# ── Public service functions ───────────────────────────────────────────────────

def enhance_cv(
    analysis_id: str,
    phase1_data: dict,
    phase2_data: dict,
    target_job: str | None = None,
) -> dict:
    """
    Run Phase 4 and save the result as a JSON sidecar file next to the analysis.
    Saved to: uploads/resumes/{analysis_id}_enhancement.json
    """
    from app.models.phase4 import run_phase4
    import json, os

    phase4_result = run_phase4(phase1_data, phase2_data, target_job)

    output = {
        "analysis_id": analysis_id,
        "target_job": target_job,
        "phase4": phase4_result,
    }

    output_path = os.path.join("uploads/resumes", f"{analysis_id}_enhancement.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"[CV Enhancement] Saved to {output_path}")
    return output


def get_enhancement(
    db: Session,
    analysis_id: int,
    user_id: int,
) -> EnhancementResponse | None:
    """
    Fetch the most recent enhancement for a given analysis.
    Returns None if Phase 4 hasn't finished yet (Flutter should poll).
    """
    row = (
        db.query(CVEnhancement)
        .filter(
            CVEnhancement.analysis_id == analysis_id,
            CVEnhancement.user_id == user_id,
        )
        .order_by(CVEnhancement.created_at.desc())
        .first()
    )
    if not row:
        return None
    return _row_to_response(row)


def export_cv_pdf(
    db: Session,
    analysis_id: int,
    user_id: int,
) -> str:
    """
    Generate a PDF of the enhanced CV and return its file path.
    Uses reportlab. Saves to backend/uploads/cv_exports/.
    """
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import cm
    from reportlab.lib import colors
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable

    row = (
        db.query(CVEnhancement)
        .filter(
            CVEnhancement.analysis_id == analysis_id,
            CVEnhancement.user_id == user_id,
        )
        .order_by(CVEnhancement.created_at.desc())
        .first()
    )
    if not row:
        raise ValueError("No enhancement found for this analysis. Run enhancement first.")

    data = _parse_phase4_json(row.phase4_json)

    # ── Output path ───────────────────────────────────────────────────────────
    export_dir = os.path.join("uploads", "cv_exports")
    os.makedirs(export_dir, exist_ok=True)
    filename = f"{user_id}_{analysis_id}.pdf"
    filepath = os.path.join(export_dir, filename)

    # ── Styles ────────────────────────────────────────────────────────────────
    styles = getSampleStyleSheet()
    BRAND = colors.HexColor("#4F46E5")   # Indigo — adjust to match your app's brand color

    title_style = ParagraphStyle("Title", parent=styles["Heading1"], fontSize=20, textColor=BRAND, spaceAfter=4)
    h2_style = ParagraphStyle("H2", parent=styles["Heading2"], fontSize=13, textColor=BRAND, spaceBefore=14, spaceAfter=4)
    body_style = ParagraphStyle("Body", parent=styles["Normal"], fontSize=10, leading=15, spaceAfter=4)
    strike_style = ParagraphStyle("Strike", parent=body_style, textColor=colors.gray)
    label_style = ParagraphStyle("Label", parent=body_style, fontName="Helvetica-Bold", textColor=colors.HexColor("#374151"))
    caption_style = ParagraphStyle("Caption", parent=body_style, fontSize=8, textColor=colors.gray)

    # ── Build document ────────────────────────────────────────────────────────
    doc = SimpleDocTemplate(
        filepath,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    story = []

    # Header
    story.append(Paragraph("Enhanced CV", title_style))
    story.append(Paragraph(
        f"Generated by ResumeAnalyzer · {datetime.now().strftime('%B %d, %Y')}",
        caption_style,
    ))
    story.append(HRFlowable(width="100%", thickness=1, color=BRAND, spaceAfter=10))

    # ── 1. Professional Summary ───────────────────────────────────────────────
    story.append(Paragraph("Professional Summary", h2_style))
    story.append(Paragraph(data["rewritten_sections"]["summary"], body_style))

    # ── 2. Experience Bullets ─────────────────────────────────────────────────
    story.append(Paragraph("Experience — Improved Bullets", h2_style))
    for bullet in data["rewritten_sections"]["experience"]:
        story.append(Paragraph(f"<strike>{bullet['original']}</strike>", strike_style))
        story.append(Paragraph(f"✦  {bullet['improved']}", body_style))
        story.append(Spacer(1, 4))

    # ── 3. Recommended Certificates ──────────────────────────────────────────
    story.append(Paragraph("Recommended Certificates", h2_style))

    cert_table_data = [["#", "Certificate", "Provider", "Why it matters"]]
    for cert in sorted(data["certificates"], key=lambda c: c["priority"]):
        cert_table_data.append([
            str(cert["priority"]),
            cert["name"],
            cert["provider"],
            cert["why"],
        ])

    cert_table = Table(cert_table_data, colWidths=[1 * cm, 5 * cm, 3.5 * cm, 7.5 * cm])
    cert_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), BRAND),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.HexColor("#F9FAFB"), colors.white]),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E5E7EB")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(cert_table)

    # ── 4. Skill Gaps ─────────────────────────────────────────────────────────
    story.append(Paragraph("Skill Gaps", h2_style))

    importance_order = {"high": 0, "medium": 1, "low": 2}
    importance_color = {
        "high": colors.HexColor("#DC2626"),
        "medium": colors.HexColor("#D97706"),
        "low": colors.HexColor("#059669"),
    }

    for gap in sorted(data["skill_gaps"], key=lambda g: importance_order.get(g["importance"], 9)):
        color = importance_color.get(gap["importance"], colors.black)
        story.append(Paragraph(
            f'<font color="{color.hexval()}"><b>{gap["skill"]}</b></font>'
            f' <font size="8" color="grey">[{gap["importance"].upper()}]</font>',
            label_style,
        ))
        story.append(Paragraph(gap["how_to_acquire"], body_style))
        story.append(Spacer(1, 4))

    # ── Build PDF ─────────────────────────────────────────────────────────────
    doc.build(story)

    # Persist export path on the DB row
    row.export_path = filepath
    db.commit()

    return filepath
