import json
import re
import os
from groq import Groq
from dotenv import load_dotenv

from app.models.phase1 import analyze_resume_phase1
from app.models.phase2 import run_phase2


# ─────────────────────────────
# LOAD ENV
# ─────────────────────────────
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env")
load_dotenv(env_path)

api_key = os.getenv("GROQ_API_KEY")

if not api_key:
    raise ValueError(
        "❌ GROQ_API_KEY not found in .env file!\n"
        "Please create a .env file in the backend directory with:\n"
        "  GROQ_API_KEY=your_key_from_https://console.groq.com"
    )

if not api_key.startswith('gsk_'):
    raise ValueError(
        "❌ GROQ_API_KEY appears invalid (should start with 'gsk_')\n"
        "Get a valid key from: https://console.groq.com/keys"
    )

client = Groq(api_key=api_key)

# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION — anti-hallucination
# ─────────────────────────────────────────────────────────────────────────────
def validate_llm_output(phase3_result: dict, phase1_result: dict, phase2_result: dict) -> dict:
    known_skills = set(s.lower() for s in phase1_result.get("skills", []))
 
    for match in phase2_result.get("matches", []):
        gap = match.get("skill_gap", {})
        for s in gap.get("matched_required", []):  known_skills.add(s.lower())
        for s in gap.get("missing_required", []):   known_skills.add(s.lower())
        for s in gap.get("matched_preferred", []): known_skills.add(s.lower())
        for s in gap.get("missing_preferred", []): known_skills.add(s.lower())
 
    for rec in phase2_result.get("recommendations", []):
        known_skills.add(rec.get("skill", "").lower())
 
    hallucinated      = []
    validated_roadmap = []
 
    for item in phase3_result.get("learning_roadmap", []):
        skill = item.get("skill", "").lower()
        if skill and skill not in known_skills:
            hallucinated.append(skill)
        else:
            validated_roadmap.append(item)
 
    phase3_result["learning_roadmap"] = validated_roadmap
    phase3_result["validation_report"] = {
        "status":                         "clean" if not hallucinated else "issues_found",
        "hallucinated_skills_removed":    hallucinated,
        "known_skill_pool_size":          len(known_skills),
        "roadmap_items_after_validation": len(validated_roadmap),
    }
    return phase3_result


# ─────────────────────────────
# PROMPTS
# ─────────────────────────────
SYSTEM_PROMPT = """
You are an expert AI resume analyzer and career advisor.

You will receive:
1. Extracted resume information (Phase 1).
2. Job matching results and learning recommendations (Phase 2).
Phase 2 recommendations already contain: skill, priority, resource, url, est_hours.

Rules:
- Use ONLY skills, matched skills, and missing skills present in Phase 2.
- Do not invent new skill gaps.
- Career path reason must use matched_required/matched_preferred skills only.
- Learning roadmap must use ONLY Phase 2 missing skills.
- Each roadmap item must copy resource, url, est_hours from Phase 2 recommendations exactly.
- Interview questions must be role-specific for the TOP matched job title only.
- Return ONLY valid JSON. No markdown. No text outside the JSON.
"""

def build_prompt(phase1_result: dict, phase2_result: dict) -> str:
    matches = phase2_result.get("matches", [{}])
    top_job = matches[0] if matches else {}
    top_job_title = top_job.get("title", "the top matched job")
    top_required  = (
        top_job.get("skill_gap", {}).get("matched_required", []) +
        top_job.get("skill_gap", {}).get("missing_required", [])
    )
 
    return f"""
Candidate Resume Data (Phase 1):
{json.dumps(phase1_result, indent=2, ensure_ascii=False)}
 
Job Matching Results + Learning Recommendations (Phase 2):
{json.dumps(phase2_result, indent=2, ensure_ascii=False)}
 
Top Matched Job: "{top_job_title}"
Required Skills for Interview Questions: {json.dumps(top_required)}
 
Generate a professional AI analysis in this exact JSON format:
 
{{
  "resume_feedback": {{
    "overall_score": <integer 0-100>,
    "strengths":    [<string>, ...],
    "weaknesses":   [<string>, ...],
    "improvements": [<string>, ...],
    "summary":      "<string>"
  }},
  "career_path": {{
    "recommended_path":  "<string>",
    "reason":            "<string — use only matched skills from Phase 2>",
    "alternative_paths": [<string>, ...]
  }},
  "interview_questions": [
    {{
      "question":   "<role-specific question for {top_job_title}>",
      "category":   "<Technical | Behavioral | Situational>",
      "difficulty": "<Easy | Medium | Hard>"
    }}
  ],
  "learning_roadmap": [
    {{
      "skill":             "<missing skill from Phase 2 recommendations>",
      "priority":          "<copy priority from Phase 2>",
      "reason":            "<why this skill matters for matched jobs>",
      "estimated_time":    "<est_hours from Phase 2 — e.g. ~30 hours>",
      "resource_title":    "<copy resource field from Phase 2>",
      "resource_url":      "<copy url field from Phase 2>",
      "resource_platform": "<platform name inferred from the url>"
    }}
  ],
  "final_recommendation": "<string>"
}}
"""


# ─────────────────────────────
# CLEAN RESPONSE
# ─────────────────────────────
def clean_json_response(raw: str) -> str:
    raw = raw.strip()

    if raw.startswith("```"):
        raw = re.sub(r"^```json\s*", "", raw)
        raw = re.sub(r"^```\s*", "", raw)
        raw = re.sub(r"\s*```$", "", raw)

    return raw.strip()


# ─────────────────────────────
# PHASE 3
# ─────────────────────────────
def run_phase3(phase1_result: dict, phase2_result: dict) -> dict:
    print("\n[Phase 3] Starting AI analysis...")
    
    try:
        print("[Phase 3] Building prompt...")
        prompt = build_prompt(phase1_result, phase2_result)
        print(f"[Phase 3] Prompt built successfully ({len(prompt)} chars)")
        
        print("[Phase 3] Sending request to Groq API...")
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            max_tokens=2500,
        )

        raw = response.choices[0].message.content
        cleaned = clean_json_response(raw)

        result = json.loads(cleaned)
        result = validate_llm_output(result, phase1_result, phase2_result)
     
        print("[Phase 3] ✅ AI analysis completed.")
        return result
    
    except Exception as e:
        error_type = type(e).__name__
        print(f"[Phase 3] ❌ ERROR: {error_type}: {str(e)}")
        
        # Check if it's an authentication error
        if "401" in str(e) or "invalid_api_key" in str(e).lower() or "authentication" in error_type.lower():
            print("[Phase 3] 🔑 API Key Issue Detected!")
            print("[Phase 3] Please get a valid GROQ_API_KEY from: https://console.groq.com/keys")
            print("[Phase 3] Then update your backend/.env file with the new key")
        
        import traceback
        tb = traceback.format_exc()
        print(f"[Phase 3] Traceback: {tb}")
        raise


# ─────────────────────────────
# MAIN
# ─────────────────────────────
if __name__ == "__main__":
    cv_path = "CV_Malak.pdf"

    phase1_result = analyze_resume_phase1(cv_path)
    phase2_result = run_phase2(phase1_result, top_k=3)
    phase3_result = run_phase3(phase1_result, phase2_result)

    print("\n" + "=" * 60)
    print("PHASE 3 RESULTS")
    print("=" * 60)

    print(json.dumps(phase3_result, indent=2, ensure_ascii=False))

    with open("phase3_result.json", "w", encoding="utf-8") as f:
        json.dump(phase3_result, f, indent=2, ensure_ascii=False)

    print("\nFull JSON saved → phase3_result.json")