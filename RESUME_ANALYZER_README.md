# Resume Analyzer System

A comprehensive AI-powered resume analyzer that extracts resume data, matches with job opportunities, and provides personalized career recommendations using Flutter frontend and Python backend.

## System Architecture

### 3-Phase Analysis

```
Phase 1: Resume Extraction
├── Extract text from PDF using pdfplumber
├── Extract personal info (email, phone, name, location)
├── Use spaCy NLP for entity recognition
├── Extract skills using keyword matching
├── Parse education, projects, and experience
└── Output: JSON with structured resume data

Phase 2: Job Matching
├── Build candidate profile from Phase 1
├── Query SerpAPI for real jobs (fallback to local DB)
├── Use TF-IDF for keyword similarity
├── Use Sentence Transformers for semantic matching
├── Calculate hybrid match scores
└── Output: Ranked jobs with skill gaps and recommendations

Phase 3: AI Analysis
├── Send Phase 1 + Phase 2 to Groq LLM
├── Generate resume feedback & scoring
├── Suggest career paths
├── Generate role-specific interview questions
├── Create personalized learning roadmap
└── Output: AI-powered career recommendations
```

## Backend Setup

### Prerequisites
```bash
pip install fastapi uvicorn python-multipart
pip install pdfplumber spacy
pip install scikit-learn
pip install sentence-transformers
pip install groq python-dotenv
pip install requests  # for SerpAPI
```

### Environment Variables (.env)
```
GROQ_API_KEY=your_groq_api_key
SERPAPI_KEY=your_serpapi_key  # Optional - fallback to local DB if not provided
```

### Running Backend
```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### API Endpoints

#### 1. **Upload & Analyze Resume**
```
POST /api/resume/analyze
Content-Type: multipart/form-data

Parameters:
- file: PDF resume file (required)
- top_k: Number of job matches (default: 3)
- use_external_jobs: Use SerpAPI (default: true)
- location: Job location (default: Egypt)

Response:
{
  "phase1": { extracted resume data },
  "phase2": { job matches and recommendations },
  "phase3": { AI analysis },
  "analysis_id": "analysis_20240429_120000",
  "status": "success"
}
```

#### 2. **Get Analysis History**
```
GET /api/resume/history

Response:
{
  "analyses": [
    { "analysis_id": "...", "filename": "...", "timestamp": "..." },
    ...
  ],
  "count": N
}
```

#### 3. **Retrieve Specific Analysis**
```
GET /api/resume/history/{analysis_id}
```

#### 4. **Download Analysis**
```
GET /api/resume/download/{analysis_id}
```

#### 5. **Delete Analysis**
```
DELETE /api/resume/history/{analysis_id}
```

## Frontend Setup (Flutter)

### Required Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  file_picker: ^5.3.0
  url_launcher: ^6.1.0
```

### Installation
```bash
cd frontend
flutter pub get
```

### Running Flutter App
```bash
flutter run
```

## UI Pages

### 1. **Resume Upload Screen** (`resume_upload_screen.dart`)
- File picker for PDF selection
- Phase descriptions (1, 2, 3)
- Upload button with progress indicator
- Error handling and feedback

### 2. **Resume Analysis Screen** (`resume_analysis_screen.dart`)
- Tab-based navigation for 5 phases
- **Extracted Data Tab**: Personal info, skills, education, projects, experience
- Navigation to other phases

### 3. **Job Matches Screen** (`job_matches_screen.dart`)
**Phase 2 Results:**
- Summary with career level
- Ranked job matches with:
  - Match score (0-100%)
  - Company and location
  - Job level badge
  - Skill coverage bar
  - Your skills vs. needed skills
  - Apply button (links to job)

### 4. **Learning Roadmap Screen** (`learning_roadmap_screen.dart`)
**Phase 2 + Phase 3:**
- Recommended skills with priority (High/Medium/Low)
- Estimated learning time
- Resource recommendations with links
- Personalized learning path steps

### 5. **Interview Questions Screen** (`interview_questions_screen.dart`)
**Phase 3 Results:**
- Role-specific interview questions
- Categorized (Technical, Behavioral, Situational)
- Difficulty levels (Easy, Medium, Hard)
- Answer tips using STAR method

### 6. **Career Path Screen** (`career_path_screen.dart`)
**Phase 3 Results:**
- Resume score (0-100%)
- Strengths, weaknesses, improvements
- Recommended career path
- Alternative career paths
- Next steps checklist

## Phase Details

### Phase 1: Resume Extraction

**Input:** PDF file
**Process:**
1. Extract text from PDF
2. Run spaCy NLP for entity recognition
3. Extract using regex:
   - Email: `[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}`
   - Phone: `[\d\s\-\(\)]{10,15}`
4. Extract name from first 5 lines
5. Match skills against KNOWN_SKILLS list
6. Parse education, projects, internships, experience

**Output:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+20 10 1234 5678",
  "location": "Cairo, Egypt",
  "github": "https://github.com/johndoe",
  "skills": ["python", "machine learning", "tensorflow", ...],
  "experience_years": 2.5,
  "internship_count": 3,
  "education": [{ "institution": "...", "degree": "...", "year": "..." }],
  "projects": ["Project 1", "Project 2", ...]
}
```

### Phase 2: Job Matching

**Input:** Phase 1 output
**Process:**
1. Enrich skills with aliases and inferred skills
2. Build profile text from candidate data
3. Query SerpAPI or use local JOB_DB
4. For each job:
   - Extract required/preferred skills
   - Compute skill gap
   - Calculate hybrid score:
     - 10% TF-IDF similarity
     - 50% Semantic similarity (Sentence Transformers)
     - 30% Skill coverage
     - 10% Experience fit
5. Rank by match score
6. Generate learning recommendations

**Output:**
```json
{
  "career_level": "Junior",
  "matches": [
    {
      "rank": 1,
      "title": "ML Engineer",
      "company": "TechCorp",
      "match_score": 87,
      "skill_gap": {
        "matched_required": ["python", "tensorflow"],
        "missing_required": ["docker"],
        "coverage_pct": 80
      }
    },
    ...
  ],
  "recommendations": [
    {
      "skill": "docker",
      "priority": "High",
      "est_hours": 10,
      "resource": "Docker 101",
      "url": "..."
    },
    ...
  ]
}
```

### Phase 3: AI Analysis

**Input:** Phase 1 + Phase 2 outputs
**Process:**
1. Send to Groq LLM (llama-3.3-70b-versatile)
2. LLM generates:
   - Resume feedback (score, strengths, weaknesses)
   - Career path recommendation
   - Role-specific interview questions
   - Learning roadmap
3. Validate output against known skills (anti-hallucination)

**Output:**
```json
{
  "resume_feedback": {
    "overall_score": 75,
    "strengths": ["Strong technical foundation", "..."],
    "weaknesses": ["Limited project portfolio", "..."],
    "improvements": ["Build more projects", "..."]
  },
  "career_path": {
    "recommended_path": "ML Engineer → Senior ML Engineer",
    "reason": "Your strong Python and ML skills align well with..."
  },
  "interview_questions": [
    {
      "question": "Tell me about a machine learning project...",
      "category": "Technical",
      "difficulty": "Medium"
    },
    ...
  ],
  "learning_roadmap": [
    {
      "skill": "docker",
      "priority": "High",
      "resource_title": "Docker 101",
      "est_hours": "~10 hours"
    },
    ...
  ]
}
```

## Configuration

### Known Skills (phase1.py)
Edit `KNOWN_SKILLS` list to include additional skills for keyword matching:
```python
KNOWN_SKILLS = [
    "python", "java", "c++", ...,
    "machine learning", "deep learning", ...,
    # Add your custom skills here
]
```

### Job Database (phase2.py)
Edit `JOB_DB` to add more local job templates:
```python
JOB_DB = [
    {
        "title": "Software Engineer",
        "level": "Junior",
        "required": ["python", "git"],
        "preferred": ["docker", "aws"],
        ...
    },
    ...
]
```

### Learning Resources (phase2.py)
Add resources to `LEARNING_MAP`:
```python
LEARNING_MAP = {
    "skill_name": {
        "resource": "Course Title",
        "url": "https://...",
        "hours": 10,
    },
    ...
}
```

## Error Handling

### Backend
- PDF validation (must be .pdf file)
- Text extraction failure handling
- NLP processing timeout
- SerpAPI fallback to local DB
- LLM timeout handling

### Frontend
- File picker errors
- Network timeout (5 minutes)
- API error responses
- User-friendly error messages
- Loading states

## Performance Optimization

- **Lazy Loading**: Sentence Transformers loaded only when needed
- **Caching**: Job database and learning maps cached in memory
- **Async Processing**: API calls non-blocking
- **Progressive Rendering**: Phase-by-phase result display

## Customization

### Change Primary Color
Update in all Flutter screens:
```dart
const primary = Color(0xFF5C6BC0);  // Change this
```

### Change API Base URL
Update in `resume_analyzer_service.dart`:
```dart
static const String baseUrl = 'http://your-api:8000/api/resume';
```

### Change Job Location
Update upload endpoint parameters:
```dart
location: 'New York',  // Change this
```

## Troubleshooting

### Common Issues

1. **spaCy Model Not Found**
   ```bash
   python -m spacy download en_core_web_sm
   ```

2. **GROQ_API_KEY Not Set**
   - Create `.env` file in backend root
   - Add your Groq API key

3. **SerpAPI Not Working**
   - Set `use_external_jobs=false` in API call
   - System will fallback to local JOB_DB

4. **Sentence Transformers Loading Slow**
   - First run takes time to download model
   - Subsequent runs use cache

5. **Flutter HTTP Errors**
   - Ensure backend is running on correct host:port
   - Check CORS settings
   - Verify API endpoints

## Future Enhancements

- [ ] Add LinkedIn integration
- [ ] Real-time job market analysis
- [ ] Salary predictions based on skills
- [ ] Networking recommendations
- [ ] Interview preparation videos
- [ ] Real-time skill trending
- [ ] Mobile app optimization
- [ ] Dark mode support
- [ ] Multi-language support
- [ ] PDF report generation

## License

MIT License

## Support

For issues and feature requests, please open an issue in the repository.
