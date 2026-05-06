"""
Phase 2 — Job Matching & Recommendations
==========================================
Fixed version — see review comments inline (marked FIX)
"""  
from __future__ import annotations
import re
import json
import math
import numpy as np
from typing import Optional
import os
import requests
from dotenv import load_dotenv

os.environ["TOKENIZERS_PARALLELISM"] = "false"
os.environ["TRITON_INTERPRET"] = "1"

load_dotenv()

try:
    from sentence_transformers import SentenceTransformer
    _ST_AVAILABLE = True
except ImportError:
    _ST_AVAILABLE = False

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def fetch_jobs_serpapi(query: str, location: str = "Egypt") -> list[dict]:
    api_key = os.getenv("SERPAPI_KEY")

    if not api_key:
        print("[Jobs] SERPAPI_KEY not found. Using local JOB_DB.")
        return []

    try:
        params = {
            "engine": "google_jobs",
            "q": query,
            "location": location,
            "api_key": api_key,
        }

        response = requests.get(
            "https://serpapi.com/search",
            params=params,
            timeout=20
        )
        response.raise_for_status()

        data = response.json()
        jobs = []

        for job in data.get("jobs_results", []):
            description = job.get("description", "")

            if not description:
                continue
            apply_options = job.get("apply_options", [])

            apply_link = ""
            if apply_options and isinstance(apply_options, list):
                apply_link = apply_options[0].get("link", "")

            jobs.append({
                "title": job.get("title", "Unknown Job"),
                "company": job.get("company_name", "Unknown Company"),
                "location": job.get("location", location),
                "level": "Unknown",
                "path": "External Jobs",
                "description": description,
                "required": [],
                "preferred": [],
                "source": "serpapi",
                "apply_link": apply_link,
            })

        return jobs

    except Exception as e:
        print(f"[Jobs] SerpAPI failed: {e}")
        print("[Jobs] Falling back to local JOB_DB.")
        return []


def get_job_database(query: str = "AI Machine Learning Engineer", location: str = "Egypt") -> list[dict]:
    external_jobs = fetch_jobs_serpapi(query, location)

    if external_jobs:
        print(f"[Jobs] Loaded {len(external_jobs)} jobs from SerpAPI.")
        return external_jobs

    print(f"[Jobs] Using local JOB_DB with {len(JOB_DB)} jobs.")
    return JOB_DB

    
def build_query_from_skills(skills):
    if "machine learning" in skills or "deep learning" in skills:
        return "AI Machine Learning Engineer"
    elif "nlp" in skills:
        return "NLP Engineer"
    elif "computer vision" in skills:
        return "Computer Vision Engineer"
    else:
        return "Software Engineer"
    
JOB_DB = [
    {
        "title":       "AI / ML Engineer",
        "level":       "Junior–Mid",
        "path":        "Artificial Intelligence",
        "description": (
            "Design, train and deploy machine learning and deep learning models. "
            "Build AI pipelines using Python, TensorFlow or PyTorch. "
            "Work on NLP tasks such as text classification, named entity recognition, "
            "and generative AI applications. Experience with multi-agent systems, "
            "LLM prompt engineering, and AI agent frameworks is a strong plus. "
            "Data wrangling with pandas and numpy, model evaluation, and REST API deployment."
        ),
        "required":  ["python", "machine learning", "deep learning", "tensorflow", "pytorch",
                      "pandas", "numpy", "git"],
        "preferred": ["nlp", "prompt engineering", "generative ai", "multi-agent",
                      "fastapi", "docker", "aws"],
    },
    {
        "title":       "NLP Engineer",
        "level":       "Junior–Mid",
        "path":        "Artificial Intelligence",
        "description": (
            "Build natural language processing systems: text classification, sentiment analysis, "
            "named entity recognition, question answering, and text generation. "
            "Proficiency in Python, spaCy, NLTK, HuggingFace Transformers. "
            "Experience with LLMs, prompt engineering, and fine-tuning language models. "
            "Work with large text datasets, embeddings, and vector databases."
        ),
        "required":  ["python", "nlp", "machine learning", "deep learning", "git"],
        "preferred": ["spacy", "pytorch", "tensorflow", "prompt engineering",
                      "generative ai", "sql", "docker"],
    },
    {
        "title":       "Computer Vision Engineer",
        "level":       "Junior–Mid",
        "path":        "Artificial Intelligence",
        "description": (
            "Develop computer vision systems for object detection, image segmentation, "
            "medical imaging, and video analysis. "
            "Use YOLO, OpenCV, TensorFlow or PyTorch for model development. "
            "Experience with image processing pipelines, data augmentation, and model deployment. "
            "Python proficiency required. Medical imaging or industrial inspection experience is a plus."
        ),
        "required":  ["python", "computer vision", "image processing", "deep learning",
                      "machine learning", "git"],
        "preferred": ["yolo", "opencv", "pytorch", "tensorflow", "docker"],
    },
    {
        "title":       "Data Scientist",
        "level":       "Junior",
        "path":        "Data & Analytics",
        "description": (
            "Analyze structured and unstructured data to extract business insights. "
            "Build predictive models: classification, regression, and clustering using scikit-learn. "
            "Strong Python, pandas, numpy, and SQL skills required. "
            "Visualize results with matplotlib or seaborn. "
            "Experience with NLP or computer vision is a strong differentiator."
        ),
        "required":  ["python", "machine learning", "sql", "pandas", "numpy", "git"],
        "preferred": ["deep learning", "nlp", "scikit-learn", "tensorflow",
                      "pytorch", "docker", "aws"],
    },
    {
        "title":       "Python Backend Developer",
        "level":       "Junior",
        "path":        "Backend Engineering",
        "description": (
            "Build and maintain RESTful APIs using Python frameworks such as FastAPI or Django. "
            "Design relational databases with PostgreSQL or MySQL. "
            "Write clean, testable code with proper documentation. "
            "Experience with Docker, CI/CD, and cloud platforms (AWS/GCP) is a plus. "
            "Strong understanding of algorithms, data structures, and Linux environments."
        ),
        "required":  ["python", "sql", "git", "linux", "rest api"],
        # FIX 4: removed duplicate "docker"
        "preferred": ["fastapi", "django", "docker", "postgresql", "aws", "algorithms"],
    },
    {
        "title":       "Full Stack Web Developer",
        "level":       "Junior",
        "path":        "Web Development",
        "description": (
            "Develop web applications with HTML, CSS, JavaScript on the frontend "
            "and Node.js or PHP on the backend. "
            "Integrate SQL databases and REST APIs. "
            "Experience with React or Vue frameworks, responsive design, and cross-browser compatibility. "
            "Familiarity with version control (Git) and basic deployment workflows."
        ),
        "required":  ["html", "css", "javascript", "sql", "git"],
        "preferred": ["nodejs", "php", "react", "vue", "rest api",
                      "postgresql", "mongodb", "docker"],
    },
    {
        "title":       "Software Test Engineer",
        "level":       "Junior",
        "path":        "Quality Assurance",
        "description": (
            "Design and execute test plans for web and backend systems. "
            "Perform functional, regression, and performance testing. "
            "Use JMeter for load testing and API simulation. "
            "Write automated test scripts using Python or Java. "
            "Experience with Agile/Scrum workflows and bug tracking tools like Jira."
        ),
        "required":  ["jmeter", "python", "sql", "git"],
        "preferred": ["java", "agile", "scrum", "jira", "rest api",
                      "linux", "docker"],
    },
]


# ── LEARNING_MAP ─────────────────────────────────────────────────────────────
# Single source of truth for learning resources.
# Each entry now includes a "url" field used by Phase 3 PDF report.
# ─────────────────────────────────────────────────────────────────────────────
LEARNING_MAP = {
    "git": {
        "resource": "Git & GitHub Crash Course — freeCodeCamp (YouTube, free)",
        "url":      "https://www.youtube.com/watch?v=RGOj5yH7evk",
        "hours":    6,
    },
    "pytorch": {
        "resource": "fast.ai Practical Deep Learning (free)",
        "url":      "https://course.fast.ai/",
        "hours":    40,
    },
    "tensorflow": {
        "resource": "TensorFlow Developer Certificate — Coursera",
        "url":      "https://www.coursera.org/professional-certificates/tensorflow-in-practice",
        "hours":    60,
    },
    "scikit-learn": {
        "resource": "Scikit-learn docs + Kaggle Learn ML",
        "url":      "https://scikit-learn.org/stable/getting_started.html",
        "hours":    15,
    },
    "spacy": {
        "resource": "spaCy Course (free at spacy.io/usage)",
        "url":      "https://spacy.io/usage",
        "hours":    10,
    },
    "fastapi": {
        "resource": "FastAPI official tutorial",
        "url":      "https://fastapi.tiangolo.com/tutorial/",
        "hours":    8,
    },
    "docker": {
        "resource": "Docker 101 — Play with Docker (free labs)",
        "url":      "https://labs.play-with-docker.com/",
        "hours":    10,
    },
    "aws": {
        "resource": "AWS Cloud Practitioner — AWS Skill Builder (free)",
        "url":      "https://explore.skillbuilder.aws/learn/course/134",
        "hours":    30,
    },
    "postgresql": {
        "resource": "PostgreSQL Tutorial",
        "url":      "https://www.postgresqltutorial.com/",
        "hours":    12,
    },
    "rest api": {
        "resource": "REST API Design — Postman Learning Center",
        "url":      "https://learning.postman.com/docs/designing-and-developing-your-api/the-api-workflow/",
        "hours":    6,
    },
    "agile": {
        "resource": "Agile Fundamentals — Coursera (Google PM cert)",
        "url":      "https://www.coursera.org/professional-certificates/google-project-management",
        "hours":    20,
    },
    "jira": {
        "resource": "Atlassian Jira Fundamentals (free badge)",
        "url":      "https://university.atlassian.com/student/path/815443-jira-fundamentals",
        "hours":    4,
    },
    "react": {
        "resource": "React Docs + Scrimba React course",
        "url":      "https://react.dev/learn",
        "hours":    30,
    },
    "opencv": {
        "resource": "OpenCV Python tutorials",
        "url":      "https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html",
        "hours":    12,
    },
    "yolo": {
        "resource": "Ultralytics YOLO docs + Roboflow tutorials",
        "url":      "https://docs.ultralytics.com/",
        "hours":    10,
    },
    "pandas": {
        "resource": "Pandas Getting Started docs + Kaggle pandas course",
        "url":      "https://pandas.pydata.org/docs/getting_started/index.html",
        "hours":    8,
    },
    "numpy": {
        "resource": "NumPy Quickstart tutorial",
        "url":      "https://numpy.org/doc/stable/user/quickstart.html",
        "hours":    5,
    },
    "generative ai": {
        "resource": "DeepLearning.AI Short Courses (free) — Andrew Ng",
        "url":      "https://www.deeplearning.ai/short-courses/",
        "hours":    8,
    },
    "prompt engineering": {
        "resource": "Anthropic Prompt Engineering Guide (free)",
        "url":      "https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview",
        "hours":    4,
    },
    "multi-agent": {
        "resource": "DeepLearning.AI Multi-Agent Systems course (free)",
        "url":      "https://www.deeplearning.ai/short-courses/multi-ai-agent-systems-with-crewai/",
        "hours":    6,
    },
    "django": {
        "resource": "Django Official Tutorial",
        "url":      "https://docs.djangoproject.com/en/stable/intro/tutorial01/",
        "hours":    15,
    },
    "linux": {
        "resource": "Linux Foundation LFS101 (free edX)",
        "url":      "https://www.edx.org/learn/linux/the-linux-foundation-introduction-to-linux",
        "hours":    14,
    },
    "computer vision": {
        "resource": "CS231n Stanford — Convolutional Neural Networks (free, YouTube)",
        "url":      "https://www.youtube.com/playlist?list=PL3FW7Lu3i5JvHM8ljYj-zLfQRF3EO8sYv",
        "hours":    30,
    },
    "sql": {
        "resource": "SQLZoo + Mode Analytics SQL Tutorial (free)",
        "url":      "https://sqlzoo.net/",
        "hours":    10,
    },
    "mongodb": {
        "resource": "MongoDB University — M001 Basics (free)",
        "url":      "https://learn.mongodb.com/learning-paths/introduction-to-mongodb",
        "hours":    8,
    },
    "vue": {
        "resource": "Vue.js Official Tutorial",
        "url":      "https://vuejs.org/tutorial/",
        "hours":    12,
    },
    "kubernetes": {
        "resource": "Kubernetes Basics — Official Interactive Tutorial",
        "url":      "https://kubernetes.io/docs/tutorials/kubernetes-basics/",
        "hours":    10,
    },
}


def build_profile_text(phase1: dict) -> str:
    parts = []

    if phase1.get("skills"):
        skills_str = " ".join(phase1["skills"])
        parts.append(f"Skills: {skills_str}. {skills_str}. {skills_str}.")

    for proj in phase1.get("projects", []):
        parts.append(f"Project: {proj}.")

    for edu in phase1.get("education", []):
        if edu.get("degree"):
            parts.append(f"Education: {edu['degree']}.")

    exp = phase1.get("experience_years", 0)
    internships = phase1.get("internship_count", 0)
    if internships:
        parts.append(f"Professional experience: {internships} internships, {exp} years.")

    return " ".join(parts)

class HybridMatchingEngine:
    def __init__(self, jobs_db: list[dict], use_st: bool = True):
        self.jobs_db = jobs_db
        self.job_texts = [j["description"] for j in jobs_db]
        self.backend = "none"

        # TF-IDF
        self.tfidf = TfidfVectorizer(ngram_range=(1, 2), min_df=1)
        self.tfidf_matrix = self.tfidf.fit_transform(self.job_texts)

        # Sentence Transformers
        self.use_st = use_st and _ST_AVAILABLE
        self.st_model = None
        self.st_embeddings = None

        if self.use_st:
            print("[Phase 2] Loading Sentence Transformer...")
            print("LOADING MODEL...")
            self.st_model = SentenceTransformer("all-MiniLM-L6-v2",device="cpu")
            print("MODEL LOADED")
            self.st_embeddings = self.st_model.encode(
                self.job_texts,
                convert_to_numpy=True,
                normalize_embeddings=True
            )
            self.backend = "sentence-transformers"
        else:
            self.backend = "tfidf" 

        print(f"[Phase 2] Hybrid engine ready | ST enabled: {self.use_st}")

    def search(self, query_text: str, top_k: int = 3):
        top_k = min(top_k, len(self.jobs_db))

        # TF-IDF score
        q_tfidf = self.tfidf.transform([query_text])
        tfidf_scores = cosine_similarity(q_tfidf, self.tfidf_matrix)[0] * 100

        # Semantic score
        if self.use_st:
            q_emb = self.st_model.encode(
                [query_text],
                convert_to_numpy=True,
                normalize_embeddings=True
            )
            semantic_scores = cosine_similarity(q_emb, self.st_embeddings)[0] * 100
        else:
            semantic_scores = tfidf_scores

        combined = []
        for i in range(len(self.jobs_db)):
            combined.append({
                "job_idx": i,
                "tfidf_score": float(tfidf_scores[i]),
                "semantic_score": float(semantic_scores[i]),
            })

        combined.sort(
            key=lambda x: (0.4 * x["tfidf_score"]) + (0.6 * x["semantic_score"]),
            reverse=True
        )

        return combined[:top_k]
    
SKILL_ALIASES = {
    "github": "git",
    "node.js": "nodejs",
}

SKILL_INFERENCE = {
    "yolo":             ["computer vision", "opencv"],
    "image processing": ["computer vision", "opencv"],
    "deep learning":    ["numpy"],
    "machine learning": ["numpy", "pandas"],
    "generative ai":    ["prompt engineering"],
    "multi-agent":      ["prompt engineering", "generative ai"],
    "nlp":              ["python"],
}

def enrich_skills(skills: list[str]) -> list[str]:
    enriched = set(SKILL_ALIASES.get(s.lower(), s.lower()) for s in skills)
    for skill in list(enriched):
        for implied in SKILL_INFERENCE.get(skill, []):
            enriched.add(implied)
    return sorted(enriched)

def compute_skill_gap(candidate_skills: list[str], job: dict) -> dict:
    candidate = set(
    SKILL_ALIASES.get(s.lower(), s.lower())
    for s in candidate_skills
    )
    required  = set(job["required"])
    preferred = set(job["preferred"])

    matched_req  = sorted(candidate & required)
    missing_req  = sorted(required - candidate)
    matched_pref = sorted(candidate & preferred)
    missing_pref = sorted(preferred - candidate)

    coverage = round(len(matched_req) / len(required) * 100) if required else 0

    return {
        "matched_required":  matched_req,
        "missing_required":  missing_req,
        "matched_preferred": matched_pref,
        "missing_preferred": missing_pref,
        "coverage_pct":      coverage,
    }


def compute_hybrid_match_score(
    tfidf_score: float,
    semantic_score: float,
    gap: dict,
    experience_years: float,
    job_level: str,
    internship_count=0
) -> int:
    tfidf = min(tfidf_score, 100)
    semantic = min(semantic_score, 100)
    skill_score = gap["coverage_pct"]

    level_lower = job_level.lower()

    if "junior" in level_lower:
        if internship_count >= 2:
            exp_score = 100  
        elif internship_count == 1:
            exp_score = 90    
        elif experience_years >= 1:
            exp_score = 85    
        else:
            exp_score = 70    
    elif "mid" in level_lower:
        exp_score = 60 if experience_years < 1 else 75   
    else:
        exp_score = 30   

    final = (
        0.10 * tfidf +
        0.25 * semantic +   
        0.55 * skill_score +
        0.10 * exp_score
    )
    penalty = len(gap["missing_required"]) * 2   
    final = final - penalty                     

    return round(max(0, min(final, 100)))   



def compute_readiness(gap: dict, career_level: str, internship_count: int) -> dict:
    coverage = gap["coverage_pct"]
    missing_req = gap["missing_required"]

    if coverage >= 80 and len(missing_req) == 0:
        status = "Ready ✅"
        reason = "Meets all required skills."
    elif coverage >= 60:
        status = "Almost Ready ⚠️"
        reason = f"Missing {len(missing_req)} required skill(s): {', '.join(missing_req[:3])}."
    else:
        status = "Not Ready ❌"
        reason = f"Missing core skills: {', '.join(missing_req[:3])}{'...' if len(missing_req) > 3 else ''}."

    return {"status": status, "reason": reason, "coverage_pct": coverage}


def build_recommendations(matches: list[dict], candidate_skills: list[str]) -> list[dict]:
    skill_freq: dict[str, int] = {}
    for match in matches:
        gap = match["skill_gap"]
        for s in gap["missing_required"]:
            skill_freq[s] = skill_freq.get(s, 0) + 2
        for s in gap["missing_preferred"]:
            skill_freq[s] = skill_freq.get(s, 0) + 1

    if not skill_freq:
        return []

    ranked = sorted(skill_freq.items(), key=lambda x: x[1], reverse=True)

    recs = []
    for skill, freq in ranked:
        priority = "High" if freq >= 4 else ("Medium" if freq >= 2 else "Low")
        info = LEARNING_MAP.get(skill, {
            "resource": f"Search: '{skill} tutorial' on YouTube or Coursera",
            "url":      f"https://www.youtube.com/results?search_query={skill.replace(' ', '+')}+tutorial",
            "hours":    10,
        })
        # FIX 3: cleaner calculation — each required hit = 1 job, preferred = 0.5 job
        needed = math.ceil(freq / 2)
        recs.append({
            "skill":          skill,
            "priority":       priority,
            "needed_in_jobs": needed,
            "resource":       info["resource"],
            "url":            info["url"],
            "est_hours":      info["hours"],
        })

    return recs


def detect_career_level(phase1: dict) -> str:
    exp = phase1.get("experience_years", 0)
    projs = len(phase1.get("projects", []))
    internships = phase1.get("internship_count", 0)
    edu = phase1.get("education", [{}])
    gpa = edu[0].get("gpa") if edu else None

    # strong junior first (priority condition)
    if exp >= 1 or internships >= 2 or projs >= 5:
        return "Junior (Strong)"   # MODIFIED

    # junior condition
    if exp > 0 or internships == 1 or projs >= 3 or (gpa and gpa >= 3.5):
        return "Junior"   # MODIFIED

    # mid-level only if real experience
    if exp >= 3:
        return "Mid-level" 

    # fallback
    return "Entry-level / Student"   

def extract_required_skills_from_description(description: str) -> list[str]:
    text = description.lower()

    skills = [
        "python", "java", "javascript", "sql", "html", "css",
        "machine learning", "deep learning", "nlp", "computer vision",
        "pandas", "numpy", "tensorflow", "pytorch", "docker",
        "aws", "git", "github", "fastapi", "django", "react",
        "nodejs", "postgresql", "mongodb", "linux", "opencv",
        "spacy", "scikit-learn", "rest api", "kubernetes",
        "flask", "django", "jira", "agile"
    ]

    found = [
        skill for skill in skills
        if re.search(r"\b" + re.escape(skill) + r"\b", text)
    ]

    if "github" in found and "git" not in found:
        found.append("git")

    return sorted(set(found))

def filter_jobs_by_level(jobs: list[dict], career_level: str) -> list[dict]:
    if "Junior" in career_level:
        return [
            job for job in jobs
            if "senior" not in job.get("title", "").lower()
            and "lead" not in job.get("title", "").lower()
            and "principal" not in job.get("title", "").lower()
        ]
    return jobs

def run_phase2(phase1_result: dict, top_k: int = 3,use_external_jobs: bool = True,
    location: str = "Egypt") -> dict:
    print("\n[Phase 2] Starting job matching…")

    profile_text     = build_profile_text(phase1_result)
    candidate_skills = enrich_skills(phase1_result.get("skills", []))
    experience_years = phase1_result.get("experience_years", 0)
    career_level     = detect_career_level(phase1_result)


    # 2) Build search query dynamically from candidate skills
    if "machine learning" in candidate_skills or "deep learning" in candidate_skills:
        query = "AI Machine Learning Engineer"
    elif "nlp" in candidate_skills:
        query = "NLP Engineer"
    elif "computer vision" in candidate_skills:
        query = "Computer Vision Engineer"
    elif "html" in candidate_skills or "javascript" in candidate_skills:
        query = "Full Stack Web Developer"
    else:
        query = "Software Engineer"
    
    # 3) Get jobs: SerpAPI first, fallback to local JOB_DB
    if use_external_jobs:
        jobs_db = get_job_database(query=query, location=location)
    else:
        jobs_db = JOB_DB

    jobs_db = filter_jobs_by_level(jobs_db, career_level)

    # 4) Extract required skills from external job descriptions if missing
    for job in jobs_db:
        if not job.get("required"):
            job["required"] = extract_required_skills_from_description(
                job.get("description", "")
            )

        if not job.get("preferred"):
            job["preferred"] = []

    engine = HybridMatchingEngine(jobs_db=jobs_db, use_st=True)

    print(f"[Phase 2] Profile text length: {len(profile_text.split())} words")
    print(f"[Phase 2] Career level detected: {career_level}")
    print(f"[Phase 2] Search query: {query}")
    print(f"[Phase 2] Jobs loaded: {len(jobs_db)}")
    print(f"[Phase 2] Embedding backend: {engine.backend}")

    raw_results =engine.search(profile_text, top_k=top_k)

    matches = []
    for item in raw_results:
        job_idx = item["job_idx"]
        job   = jobs_db[job_idx]
        gap   = compute_skill_gap(candidate_skills, job)
        tfidf_score = item["tfidf_score"]
        semantic_score = item["semantic_score"]

        score = compute_hybrid_match_score(
            tfidf_score=tfidf_score,
            semantic_score=semantic_score,
            gap=gap,
            experience_years=experience_years,
            job_level=job["level"],
            internship_count=phase1_result.get("internship_count", 0),
    )

        matches.append({
            "rank":           len(matches) + 1,
            "title":          job["title"],
            "company": job.get("company", "N/A"),
            "apply_link": job.get("apply_link", ""),
            "location": job.get("location", location),
            "career_path":    job["path"],
            "level":          job["level"],
            "source": job.get("source", "local"),
            "match_score":    score,
            "tfidf_score": round(tfidf_score, 1),
            "semantic_score": round(semantic_score, 1),
            "skill_gap":      gap,
            "why_good_fit":   _explain_fit(gap, job, career_level),
            "readiness": compute_readiness(
                gap, 
                career_level, 
                phase1_result.get("internship_count", 0)
            ),
     })

    matches.sort(key=lambda x: x["match_score"], reverse=True)
    for i, m in enumerate(matches):
        m["rank"] = i + 1

    recommendations = build_recommendations(matches, candidate_skills)

    top = matches[0]
    # FIX 9: safe check on recommendations list
    top_gap = recommendations[0]["skill"] if recommendations else "none"
    summary = (
        f"{phase1_result.get('basic_info', {}).get('name') or phase1_result.get('name', 'The candidate')} "
        f"is a {career_level} with {len(candidate_skills)} detected skills. "
        f"Best fit: {top['title']} ({top['match_score']}% match). "
        f"Top skill gap: {top_gap}."
    )

    print(f"[Phase 2] Done — top match: {top['title']} ({top['match_score']}%)")

    # ADDED — compute confidence score before return
    def _compute_confidence(phase1: dict, matches: list) -> int:
        score = 0
        if phase1.get("name"):      score += 15
        if phase1.get("email"):     score += 10
        if phase1.get("skills"):    score += 20
        if phase1.get("projects"):  score += 15
        if phase1.get("education"): score += 10
        if matches:
            top_match = matches[0]["match_score"]
            score += int(top_match * 0.30)  # up to 30 points from match quality
        return min(score, 100)
    
    return {
        "career_level":      career_level,
        "embedding_backend": engine.backend,
        "query_used": query,
        "jobs_source": "external_serpapi_or_fallback" if use_external_jobs else "local_JOB_DB",
        "matches": matches,
        "recommendations":   recommendations,
        "summary":           summary,
        "confidence_score": _compute_confidence(phase1_result, matches),
        # FIX 10: include profile_text for Phase 3 RAG context
        "profile_text":      profile_text,
    }


def _explain_fit(gap: dict, job: dict, career_level: str) -> str:
    matched = gap["matched_required"]
    missing = gap["missing_required"]
    cov     = gap["coverage_pct"]

    fit  = "Strong fit" if cov >= 80 else ("Good fit" if cov >= 50 else "Partial fit")
    has  = ", ".join(matched[:3]) + ("…" if len(matched) > 3 else "") if matched else "none yet"
    lacks = ", ".join(missing[:3]) + ("…" if len(missing) > 3 else "") if missing else "none"

    return (
        f"{fit} — covers {cov}% of required skills. "
        f"Has: {has}. "
        f"Still needs: {lacks}."
    )


if __name__ == "__main__":
    import sys, os
    sys.path.insert(0, os.path.dirname(__file__))

    try:
        from phase1 import analyze_resume_phase1
        cv_path = sys.argv[1] if len(sys.argv) > 1 else "CV_Malak.pdf"
        print(f"[Phase 1] Analyzing {cv_path}…")
        phase1_result = analyze_resume_phase1(cv_path)
        print("[Phase 1] Done.\n")
    except Exception as e:
        print(f"[Phase 1] Could not run phase1 ({e})")

    result = run_phase2(phase1_result, top_k=3)

    print("\n" + "=" * 62)
    print("  PHASE 2 RESULTS")
    print("=" * 62)
    print(f"\nCareer Level : {result['career_level']}")
    print(f"Engine used  : {result['embedding_backend']}")
    print(f"\nSummary: {result['summary']}")

    print("\n── JOB MATCHES ──────────────────────────────────────────────")
    for m in result["matches"]:
        g = m["skill_gap"]
        print(f"\n  #{m['rank']}  {m['title']}  [{m['level']}]")
        print(f"       Source        : {m['source']}")
        print(f"       Company       : {m['company']}")
        print(f"       Apply link    : {m['apply_link']}")
        print(f"       Location      : {m['location']}")
        print(f"       Match score    : {m['match_score']}%")
        print(f"       Semantic score : {m['semantic_score']}%")
        print(f"       Skill coverage : {g['coverage_pct']}% of required")
        print(f"       Has            : {', '.join(g['matched_required']) or '—'}")
        print(f"       Missing (req)  : {', '.join(g['missing_required']) or 'none ✓'}")
        print(f"       Missing (pref) : {', '.join(g['missing_preferred']) or 'none ✓'}")
        print(f"       Why fits       : {m['why_good_fit']}")
        print(f"       Readiness      : {m['readiness']['status']} — {m['readiness']['reason']}")


    print("\n── LEARNING RECOMMENDATIONS ─────────────────────────────────")
    for r in result["recommendations"]:
        print(f"\n  [{r['priority']:6}]  {r['skill']}")
        print(f"             Needed in {r['needed_in_jobs']} matched job(s)")
        print(f"             Resource : {r['resource']}")
        print(f"             URL      : {r['url']}")
        print(f"             Est. time: ~{r['est_hours']} hours")

    print("\n" + "=" * 62)

    with open("phase2_result.json", "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print("\nFull JSON saved → phase2_result.json")