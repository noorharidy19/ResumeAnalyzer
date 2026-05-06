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
    known_skills = set(s.lower().strip() for s in phase1_result.get("skills", []))

    for match in phase2_result.get("matches", []):
        gap = match.get("skill_gap", {})
        for key in ["matched_required", "missing_required", "matched_preferred", "missing_preferred"]:
            for s in gap.get(key, []):
                known_skills.add(s.lower().strip())

    for rec in phase2_result.get("recommendations", []):
        known_skills.add(rec.get("skill", "").lower().strip())

    hallucinated = []
    validated_roadmap = []
    seen_skills = set()

    for item in phase3_result.get("learning_roadmap", []):
        skill = item.get("skill", "").lower().strip()

        if skill and skill not in known_skills:
            hallucinated.append(skill)
            continue

        if skill and skill not in seen_skills:
            seen_skills.add(skill)
            validated_roadmap.append(item)

    long_term = phase3_result.get("career_path", {}) \
                         .get("timeline", {}) \
                         .get("long_term_6_12_months", "")
    
    career_level = phase2_result.get("career_level", "")
    
    if career_level in ("Junior", "Junior (Strong)", "Entry-level / Student"):
        if any(w in long_term.lower() for w in ["senior", "lead", "principal"]):
            phase3_result["career_path"]["timeline"]["long_term_6_12_months"] = (
                "Apply for junior roles, contribute to open-source projects, "
                "or pursue internships to build practical experience."
            )

    phase3_result["learning_roadmap"] = validated_roadmap

    # copy confidence from Phase 2
    phase3_result["confidence_score"] = phase2_result.get("confidence_score", 0)

    # force readiness from top Phase 2 match exactly
    top_match = phase2_result.get("matches", [{}])[0]
    readiness = top_match.get("readiness", {})
    phase3_result["readiness_decision"] = {
        "status": readiness.get("status", "Unknown"),
        "reason": readiness.get("reason", "")
    }

    phase3_result["validation_report"] = {
        "status": "clean" if not hallucinated else "issues_found",
        "hallucinated_skills_removed": hallucinated,
        "known_skill_pool_size": len(known_skills),
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
- overall_score must be calculated from score_breakdown: add the positive values and subtract the gaps. 
- Do NOT default to 80. A candidate with no experience and many gaps should score 50-65. 
- A strong candidate with internships and high coverage should score 75-90.
- Career path reason must use matched_required/matched_preferred skills only.
- Learning roadmap MUST include ALL skills listed in Phase 2 recommendations, not just those missing from the top job. Include every skill from the recommendations list.
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
 
Readiness per job match:
{chr(10).join(f"- {m['title']}: {m['readiness']['status']} — {m['readiness']['reason']}" for m in phase2_result.get('matches', []))}
 
Top Matched Job: "{top_job_title}"
Required Skills for Interview Questions: {json.dumps(top_required)}
Candidate's Own Projects (use at least 2 in interview questions): {json.dumps(phase1_result.get('projects', [])[:3])}
At least one interview question must reference one candidate project by name from Phase 1.

Never suggest senior roles in 6 to 12 months for Junior/Entry-level candidates.
Long term must be: apply for junior roles, internships, or build portfolio projects.
STRICT RULE: The "recommended_path" field must be a broad career direction that describes a job category or role type (e.g. a general title like "Software Engineer" or "Backend Developer" or "Data Scientist"). It must NOT copy the exact job listing title. The value "{top_job_title}" is a specific job listing and is forbidden in this field — write a generalized version of it instead.
STRICT RULE: The learning_roadmap MUST contain exactly {len(phase2_result.get('recommendations', []))} items — one for each skill in the Phase 2 recommendations list above. Do not skip any skill.
- Copy confidence_score exactly from Phase 2.
- Copy readiness_decision.status and reason exactly from Phase 2 top match readiness.
- Do NOT recommend senior roles for Junior or Entry-level candidates.
- Final recommendation must separate top-job gaps from other-job gaps.
- For the top matched job, prioritize only missing_required from the top match first.

Generate a professional AI analysis in this exact JSON format:
 
{{
  "resume_feedback": {{
    "overall_score": <integer 0-100>,
    "score_breakdown": {{
        "skills_match":   "<e.g. +35 — strong Python/ML coverage>",
        "experience":     "<e.g. +20 — 2 internships>",
        "projects":       "<e.g. +15 — relevant NLP project>",
        "gaps":           "<e.g. -15 — missing TensorFlow, Docker>"
    }},
    "strengths":    [<string>, ...],
    "weaknesses":   [<string>, ...],
    "improvements": [<string>, ...],
    "summary":      "<string>"
  }},
    "readiness_decision": {{
    "status": "<Ready ✅ / Almost Ready ⚠️ / Not Ready ❌ — for the top matched job>",
    "reason": "<one sentence explaining why>"
  }},
  "career_path": {{
    "recommended_path":  "<string>",
    "reason":            "<string — use only matched skills from Phase 2>",
    "timeline": {{
        "short_term_0_3_months":  "<1-2 concrete actions>",
        "mid_term_3_6_months":    "<1-2 concrete actions>",
        "long_term_6_12_months":  "<realistic milestone based on candidate level; do not suggest senior role for Junior/Entry-level>"
    }},
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
  "confidence_score": <copy integer from Phase 2 confidence_score>,
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