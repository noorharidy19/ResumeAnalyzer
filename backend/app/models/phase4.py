import json
import anthropic

client = anthropic.Anthropic()


def run_phase4(phase1_data: dict, phase2_data: dict, target_job: str | None = None) -> dict:
    """
    Phase 4: CV Enhancement
    Takes Phase 1 (extracted CV data) and Phase 2 (job matches),
    returns rewritten sections, recommended certificates, and skill gaps.
    """

    system_prompt = """You are an expert CV coach and career advisor with deep knowledge of hiring practices.
Return ONLY valid JSON with exactly these three keys: rewritten_sections, certificates, skill_gaps.
No preamble, no explanation, no markdown — raw JSON only."""

    user_prompt = f"""
Phase 1 data (extracted CV content):
{json.dumps(phase1_data, indent=2)}

Phase 2 data (job matches and requirements):
{json.dumps(phase2_data, indent=2)}

Target job title: {target_job or "infer from the best matching job in Phase 2"}

Analyze the CV against the target role and return this exact JSON structure:

{{
  "rewritten_sections": {{
    "summary": "A compelling 3-4 sentence professional summary tailored to the target role",
    "experience": [
      {{
        "original": "exact original bullet point from the CV",
        "improved": "stronger, quantified, action-verb-led version of the same bullet"
      }}
    ]
  }},
  "certificates": [
    {{
      "name": "Full certificate name",
      "provider": "Coursera / Google / AWS / Microsoft / etc.",
      "url": "direct URL to the certificate page",
      "why": "1-2 sentences explaining why this certificate closes a gap for the target role",
      "priority": 1
    }}
  ],
  "skill_gaps": [
    {{
      "skill": "Skill name",
      "importance": "high",
      "how_to_acquire": "Concrete suggestion: course, project, tool to learn"
    }}
  ]
}}

Rules:
- Provide 5-8 improved experience bullets (pick the most impactful ones from the CV)
- Provide 4-6 certificate recommendations sorted by priority (1 = most impactful)
- Provide 5-8 skill gaps sorted by importance (high → medium → low)
- importance must be exactly one of: high, medium, low
- All URLs must be real, working links
- Bullets must start with strong action verbs (Led, Built, Reduced, Increased, etc.)
- Quantify wherever the original or context allows (%, $, time saved, team size)
"""

    message = client.messages.create(
        model="claude-opus-4-5",
        max_tokens=4096,
        messages=[
            {"role": "user", "content": user_prompt}
        ],
        system=system_prompt,
    )

    raw = message.content[0].text.strip()

    # Strip accidental markdown fences if model adds them
    if raw.startswith("```"):
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]
        raw = raw.strip()

    try:
        result = json.loads(raw)
    except json.JSONDecodeError as e:
        raise ValueError(f"Phase 4 returned invalid JSON: {e}\nRaw output: {raw[:500]}")

    # Validate required keys
    required_keys = {"rewritten_sections", "certificates", "skill_gaps"}
    missing = required_keys - set(result.keys())
    if missing:
        raise ValueError(f"Phase 4 JSON missing keys: {missing}")

    return result
