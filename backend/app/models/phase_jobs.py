"""
Phase Jobs — AI Applicant Screening
=====================================
Takes Phase 1 data (extracted CV) + a job post dict,
returns a structured match report for the company.

Follows the same pattern as phase4.py:
- Anthropic SDK  (claude-sonnet-4-20250514)
- System prompt enforces raw JSON only
- Strips accidental markdown fences
- Validates required keys before returning
"""

import json
import anthropic

client = anthropic.Anthropic()


# ─────────────────────────────────────────────
# MAIN FUNCTION
# ─────────────────────────────────────────────
def run_job_screening(phase1_data: dict, job_post: dict) -> dict:
    """
    Score a candidate's CV against a specific job posting.

    Parameters
    ----------
    phase1_data : dict
        Output of analyze_resume_phase1() — skills, experience, projects, education, etc.
    job_post : dict
        Keys expected: title, description, requirements (list[str]),
        optionally: location, job_type.

    Returns
    -------
    dict with keys:
        match_score, verdict, matched_skills, missing_skills,
        matched_experience, weak_points, summary
    """

    system_prompt = """You are a senior technical recruiter and AI hiring assistant.
Your job is to evaluate a candidate's CV against a specific job posting.
Return ONLY valid JSON with exactly the keys specified. No preamble, no explanation, no markdown fences — raw JSON only."""

    user_prompt = f"""
Job Posting:
{json.dumps(job_post, indent=2)}

Candidate CV Data (extracted by Phase 1):
{json.dumps(phase1_data, indent=2)}

Evaluate the candidate against the job posting and return exactly this JSON structure:

{{
  "match_score": <integer 0-100>,
  "verdict": "<good_fit | average_fit | weak_fit>",
  "matched_skills": [
    "<skill the candidate has that the job requires>"
  ],
  "missing_skills": [
    "<required or preferred skill the candidate is missing>"
  ],
  "matched_experience": "<1-2 sentences describing how the candidate's experience aligns with the role>",
  "weak_points": [
    "<specific gap or concern for this role>"
  ],
  "summary": "<3-4 sentence recruiter summary: what makes them suitable or not, key strengths, key gaps>"
}}

Scoring rules:
- match_score 75-100 → good_fit
- match_score 50-74  → average_fit
- match_score 0-49   → weak_fit
- Base the score on: skills coverage of requirements, years/type of experience, project relevance, education fit.
- matched_skills must be a subset of the candidate's actual skills list — do not invent skills.
- missing_skills must come from the job requirements or description — do not invent requirements.
- Provide 2-5 items for matched_skills, missing_skills, and weak_points each.
- verdict must be exactly one of: good_fit, average_fit, weak_fit (no other values).
"""

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1500,
        system=system_prompt,
        messages=[
            {"role": "user", "content": user_prompt}
        ],
    )

    raw = message.content[0].text.strip()

    # Strip accidental markdown fences
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()

    try:
        result = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"Phase Jobs returned invalid JSON: {e}\nRaw output: {raw[:500]}")

    # Validate required keys
    required_keys = {
        "match_score", "verdict", "matched_skills",
        "missing_skills", "matched_experience", "weak_points", "summary"
    }
    missing = required_keys - set(result.keys())
    if missing:
        raise ValueError(f"Phase Jobs JSON missing keys: {missing}")

    # Validate verdict value
    valid_verdicts = {"good_fit", "average_fit", "weak_fit"}
    if result.get("verdict") not in valid_verdicts:
        raise ValueError(f"Invalid verdict value: {result.get('verdict')}. Must be one of {valid_verdicts}")

    # Clamp match_score to 0-100
    result["match_score"] = max(0, min(100, int(result["match_score"])))

    return result