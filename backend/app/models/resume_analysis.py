from sqlalchemy import Column, String, JSON, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime
import uuid

class ResumeAnalysis(Base):
    __tablename__ = "resume_analyses"

    id         = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id    = Column(String, ForeignKey("users.id"), nullable=False)
    analysis_id = Column(String, nullable=False)  # e.g. "analysis_20260530_120000"
    filename   = Column(String, nullable=True)
    phase1     = Column(JSON, nullable=True)
    phase2     = Column(JSON, nullable=True)
    phase3     = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="resume_analyses")