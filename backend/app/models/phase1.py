import re
from pathlib import Path
from datetime import datetime

import pdfplumber
import spacy

nlp = spacy.load("en_core_web_sm")


# ─────────────────────────────
# STEP 1 — CHECK PDF
# ─────────────────────────────
def receive_pdf(file_path: str) -> Path:
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError("File not found")
    if path.suffix.lower() != ".pdf":
        raise ValueError("File must be PDF")
    return path


# ─────────────────────────────
# STEP 2 — EXTRACT TEXT
# ─────────────────────────────
def extract_text(pdf_path: Path) -> str:
    text = ""
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + "\n"
    if not text:
        raise ValueError("No text extracted")
    return text


# ─────────────────────────────
# STEP 3 — NLP
# ─────────────────────────────
def run_nlp(text: str):
    return nlp(text)

SECTION_HEADERS = [
    "EDUCATION",
    "PROFESSIONAL EXPERIENCE",
    "EXPERIENCE",
    "WORK EXPERIENCE",
    "PROJECTS",
    "SKILLS",
    "CERTIFICATES",
    "CERTIFICATIONS",
    "EXTRACURRICULAR ACTIVITIES",
]

def get_section(text: str, start_keywords: list[str], end_keywords: list[str]) -> str:
    lines = text.split("\n")
    collecting = False
    result = []

    for line in lines:
        clean = line.strip()
        upper = clean.upper()

        if upper in start_keywords:
            collecting = True
            continue

        if collecting and upper in end_keywords:
            break

        if collecting and clean:
            result.append(clean)

    return "\n".join(result)

# ─────────────────────────────
# STEP 4 — FEATURE EXTRACTION
# ─────────────────────────────

def extract_email(text: str):
    for line in text.split("\n"):
        collapsed = line.replace(" ", "")
        m = re.search(r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}", collapsed)
        if m:
            return m.group()
    return None


def extract_phone(text: str):
    pattern = re.compile(r"(?<!\d)(\+?[\d][\d\s\-\(\)]{9,14})(?!\d)")
    for line in text.split("\n"):
        for m in pattern.finditer(line):
            digits = re.sub(r"\D", "", m.group())
            if 10 <= len(digits) <= 15:
                return m.group().strip()
    return None


def extract_name(text: str):
    for line in text.split("\n")[:5]:
        line = line.strip()
        if 2 <= len(line.split()) <= 4 and re.match(r"^[A-Za-z\s]+$", line):
            return line
    return None

def generate_cv_warnings(features: dict) -> list[str]:
    warnings = []

    if not features.get("email"):
        warnings.append("Missing email")

    if not features.get("phone"):
        warnings.append("Missing phone number")

    if not features.get("github"):
        warnings.append("Missing GitHub profile")

    if not features.get("location"):
        warnings.append("Missing location")

    if not features.get("linkedin"):
        warnings.append("Missing LinkedIn profile")

    if not features.get("name"):
        warnings.append("Missing name")

    if not features.get("skills"):
        warnings.append("No skills detected")

    if len(features.get("projects", [])) == 0:
        warnings.append("No projects found")

    if features.get("experience_years", 0) == 0 and features.get("internship_count", 0) == 0:
        warnings.append("No experience or internships detected")

    if not features.get("education"):
        warnings.append("No education section found")

    return warnings

# ── SKILL LIST ────────────────────────────────────────────────────────────────
# FIX 1: Added missing skills that appear in Nourhan's CV:
#   - "generative ai"  (Eva Pharma internship + IBM track)
#   - "multi-agent"    (IBM Financial Advisor project)
#   - "prompt engineering" was already present ✓
#   - "github"         (listed in header + skills section) — added so alias works
#   - "agile", "scrum" — common QA skills
#   - "data structure" — listed explicitly in her skills section
# ──────────────────────────────────────────────────────────────────────────────
KNOWN_SKILLS = [
    # Programming languages
    "python", "java", "c++", "c#", "php", "javascript", "typescript",
    "dart", "kotlin", "swift", "sql", "html", "css", "prolog",
    # Frameworks & libraries
    "flutter", "react", "angular", "vue", "node.js", "nodejs",
    "django", "flask", "fastapi", "spring boot", "laravel", "express",
    # AI / ML / Data
    "machine learning", "deep learning", "nlp", "computer vision",
    "image processing", "tensorflow", "pytorch", "scikit-learn",
    "pandas", "numpy", "opencv", "spacy", "yolo",
    "generative ai", "multi-agent", "prompt engineering",
    # Databases
    "postgresql", "mysql", "mongodb", "firebase", "sqlite", "redis",
    # DevOps / Tools
    "docker", "git", "github", "linux", "aws", "azure", "unity",
    # Methodologies / Other
    "rest api", "graphql", "jira", "agile", "scrum",
    "data structure", "data analysis",
    "knowledge representation", "intelligent agents",
    # Project-specific tools
    "ezdxf", "jmeter",
]

COURSEWORK_SKILL_MAP = {
    "machine learning":     "machine learning",
    "image processing":     "image processing",
    "natural language processing": "nlp",
    "artificial intelligence": "machine learning",
    "foundation of data science": "pandas",
    "network security":     "linux",
    "distributed systems":  "linux",
}

def extract_from_coursework(text: str) -> list[str]:
    found = []
    text_lower = text.lower()
    for course, skill in COURSEWORK_SKILL_MAP.items():
        if course in text_lower and skill not in found:
            found.append(skill)
    return found


def extract_experience_years(text: str) -> float:
    """
    Only counts MM/YYYY – MM/YYYY professional date ranges.
    'YYYY – YYYY' (education ranges) are intentionally excluded.
    """
    current_year  = datetime.now().year
    current_month = datetime.now().month
    total_months  = 0

    pattern = re.compile(
        r"(\d{1,2})/(\d{4})\s*[\-\u2013\u2014]+\s*"
        r"(?:(\d{1,2})/(\d{4})|(present|current|now))",
        re.IGNORECASE,
    )
    for m in pattern.finditer(text):
        try:
            sm, sy = int(m.group(1)), int(m.group(2))
            if m.group(5):
                em, ey = current_month, current_year
            else:
                em, ey = int(m.group(3)), int(m.group(4))
            total_months += max(0, (ey - sy) * 12 + (em - sm))
        except (ValueError, TypeError):
            pass

    return round(total_months / 12, 1)


def extract_internship_count(text: str) -> int:
    seen_lines = set()
    count = 0

    # Pattern 1: MM/YYYY date range lines — each = one position
    # This is the most reliable signal
    pattern_dated = re.compile(
        r"^\S.{2,}\s+\d{1,2}/\d{4}\s*[\-\u2013\u2014]+", re.MULTILINE
    )
    for m in pattern_dated.finditer(text):
        line = m.group().strip()
        if line not in seen_lines:
            seen_lines.add(line)
            count += 1

    # Pattern 2: only for unstructured CVs — text-based mention
    # ONLY runs if Pattern 1 found nothing (avoids double counting)
    if count == 0:
        pattern_text = re.compile(
            r"(completed|finished|did|undertook|joined|worked).{0,30}"
            r"(internship|training\s+program|summer\s+program)",
            re.IGNORECASE
        )
        for m in pattern_text.finditer(text):
            line = m.group().strip()
            if line not in seen_lines:
                seen_lines.add(line)
                count += 1

    # Pattern 3: ONLY runs if both above found nothing
    # catches edge cases like "AI track" headers with no dates
    if count == 0:
        pattern_keyword = re.compile(
            r"\b(internship|training\s+program|summer\s+program|ai\s+track|data\s+track)\b",
            re.IGNORECASE
        )
        for m in pattern_keyword.finditer(text):
            start = text.rfind("\n", 0, m.start()) + 1
            end = text.find("\n", m.end())
            if end == -1:
                end = len(text)
            line = text[start:end].strip()
            if len(line) > 80:
                continue
            if line.startswith(("•", "-", "*", "·")):
                continue
            if line not in seen_lines:
                seen_lines.add(line)
                count += 1

    return count


def extract_currently_studying(text: str) -> list[str]:
    in_progress = []
    
    pattern = re.compile(
        r"(?:currently\s+(?:studying|learning|taking|enrolled\s+in))"
        r"\s+(.+?)(?:\.|$)",
        re.IGNORECASE
    )
    
    for m in pattern.finditer(text):
        segment = m.group(1).lower()
        for skill in KNOWN_SKILLS:
            skill_lower = skill.lower()
            # Use 'in' for multi-word skills, \b for single-word
            if " " in skill_lower:
                if skill_lower in segment:
                    if skill not in in_progress:
                        in_progress.append(skill)
            else:
                if re.search(r"\b" + re.escape(skill_lower) + r"\b", segment):
                    if skill not in in_progress:
                        in_progress.append(skill)
    
    return in_progress


def extract_education(text: str) -> list:
    education = []
    GPA_RE  = re.compile(r"gpa[:\s]*([0-9]\.[0-9]+)", re.IGNORECASE)
    YEAR_RE = re.compile(r"\b(20\d{2})\b")
    SECTION_HEADER = re.compile(r"^[A-Z][A-Z\s]{3,}$")

    lines = text.split("\n")
    for i, line in enumerate(lines):
        stripped = line.strip()
        if not any(kw in stripped.lower() for kw in ["university", "college", "institute"]):
            continue

        entry = {"institution": stripped, "degree": None, "gpa": None, "year": None}

        years_on_inst_line = YEAR_RE.findall(stripped)
        if years_on_inst_line:
            entry["year"] = years_on_inst_line[-1]

        for j in range(i + 1, min(i + 6, len(lines))):
            nearby = lines[j].strip()
            if SECTION_HEADER.match(nearby):
                break
            if any(kw in nearby.lower() for kw in ["major", "bachelor", "master", "phd",
                                                     "computer science", "artificial intelligence"]):
                entry["degree"] = nearby
            gm = GPA_RE.search(nearby)
            if gm:
                entry["gpa"] = float(gm.group(1))

        education.append(entry)

    return education


def extract_projects(projects_text: str) -> list:
    projects = []
    lines = [line.strip() for line in projects_text.split("\n") if line.strip()]

    bad_keywords = [
    "description", "developed", "detecting", "allows",
    "helps", "analyzing", "application", "model", "performance",
    "responsible", "classification", "approved", "preprocessing",
    "greedy", "approach", "data-driven", "provides", "system parses",
    "programing", "brute force",   # ← these are fragments, not project names
]

    for i, line in enumerate(lines):
        line_low = line.lower()

        if len(line) < 5:
            continue

        if line.endswith(")") and "(" not in line:
            continue

        if re.match(r"^[A-Za-z#/\s\+]+:$", line):
            continue

        if len(line) > 65:
            continue

        if line.endswith("."):
            continue

        if any(word in line_low for word in bad_keywords):
            continue

        if line_low in ["projects", "description"]:
            continue

        if len(line.split()) > 7:
            continue

        projects.append(line)

    # remove duplicates while preserving order
    clean_projects = []
    for p in projects:
        if p not in clean_projects:
            clean_projects.append(p)

    return clean_projects


def extract_location(text: str, doc) -> str:
    LOCATION_BLACKLIST = [
        "software engineering", "artificial intelligence", "computer science",
        "advanced", "data science", "machine learning",
        "linkedin", "github", "http", "www",  # ADDED
    ]
    # 1️⃣ Try structured location (City, Country)
    m = re.search(r"([A-Z][a-z]+(?: [A-Z][a-z]+)?,\s*(?:New\s)?[A-Z][a-z]+)", text)
    if m:
        candidate = m.group(1).strip()
        if not any(bad in candidate.lower() for bad in LOCATION_BLACKLIST):
            return candidate

    # 2️⃣ spaCy entities (with filtering)
    for ent in doc.ents:
        if ent.label_ == "GPE":
            candidate = ent.text.strip().lower()

            if candidate in LOCATION_BLACKLIST:
                continue

            # reject short fake locations like "AI"
            if len(candidate) <= 3:
                continue

            # reject if it's clearly not a place
            if any(bad in candidate for bad in LOCATION_BLACKLIST):
                continue

            return ent.text

    return None


# FIX 3: Extract GitHub URL from PDF hyperlinks or text so we don't miss it
def extract_github(text: str) -> str | None:
    # 1. Try to extract actual URL
    m = re.search(r"https?://(?:www\.)?github\.com/[A-Za-z0-9_\-]+", text)
    if m:
        return m.group()

    # 2. If only word "github" exists → return placeholder
    if "github" in text.lower():
        return "mentioned"

    return None

def has_linkedin(text: str) -> bool:
    return "linkedin" in text.lower() or "linkedin.com" in text.lower()

# ─────────────────────────────────────────────────────────
# MAIN extract_features
# ─────────────────────────────────────────────────────────
def extract_features(text: str, doc) -> dict:
    text_lower = text.lower()

    education_text = get_section(
        text,
        ["EDUCATION"],
        ["PROFESSIONAL EXPERIENCE", "EXPERIENCE", "WORK EXPERIENCE", "PROJECTS", "SKILLS", "CERTIFICATES"]
    )

    experience_text = get_section(
        text,
        ["PROFESSIONAL EXPERIENCE", "EXPERIENCE", "WORK EXPERIENCE"],
        ["PROJECTS", "SKILLS", "CERTIFICATES", "CERTIFICATIONS", "EXTRACURRICULAR ACTIVITIES"]
    )

    projects_text = get_section(
        text,
        ["PROJECTS"],
        ["SKILLS", "CERTIFICATES", "CERTIFICATIONS", "EXTRACURRICULAR ACTIVITIES"]
    )

    skills_found = []
    for s in KNOWN_SKILLS:
        pattern = re.escape(s)
        # for skills with special chars like c++, c#, node.js use exact match without \b
        if any(c in s for c in ['+', '#', '.']):
            if re.search(pattern, text_lower, re.IGNORECASE):
                skills_found.append(s)
        else:
            if re.search(r"\b" + pattern + r"\b", text_lower):
                skills_found.append(s)


    # Add currently-studying skills
    in_progress_skills = extract_currently_studying(text)
    for skill in in_progress_skills:
        if skill not in skills_found:
            skills_found.append(skill)

    coursework_skills = extract_from_coursework(text)
    for skill in coursework_skills:
        if skill not in skills_found:
            skills_found.append(skill)

    github_url = extract_github(text)
    linkedin_found = has_linkedin(text)
    if (github_url or "github" in text_lower) and "github" not in skills_found:
        skills_found.append("github")

    features = {
        "name": extract_name(text),
        "email": extract_email(text),
        "phone": extract_phone(text),
        "location": extract_location(text, doc),
        "github": github_url,
        "linkedin": linkedin_found,
        "skills": skills_found,
        "experience_years": extract_experience_years(experience_text),
        "internship_count": extract_internship_count(experience_text) or extract_internship_count(text),
        "education": extract_education(education_text),
        "projects": extract_projects(projects_text),
    }

    features["warnings"] = generate_cv_warnings(features)   # MODIFIED

    return features


# ─────────────────────────────
# PIPELINE
# ─────────────────────────────
def analyze_resume_phase1(file_path: str) -> dict:
    pdf_path = receive_pdf(file_path)
    text     = extract_text(pdf_path)
    doc      = run_nlp(text)
    return extract_features(text, doc)


# ─────────────────────────────
# TEST
# ─────────────────────────────
if __name__ == "__main__":
    import json
    result = analyze_resume_phase1("CV_Malak.pdf")
    print(json.dumps(result, indent=2, ensure_ascii=False))