from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.database import Base


class CVEnhancement(Base):
    __tablename__ = "cv_enhancements"

    id = Column(Integer, primary_key=True, index=True)
    analysis_id = Column(String, nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    target_job = Column(String(255), nullable=True)       # Optional override; NULL = inferred by AI
    phase4_json = Column(Text, nullable=False)            # Full Phase 4 JSON stored as text
    export_path = Column(String(512), nullable=True)      # Set when PDF is generated, e.g. uploads/cv_exports/1_42.pdf
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships (lazy by default — add eager loading in queries where needed)
    user = relationship("User", back_populates="cv_enhancements")
    # analysis = relationship("ResumeAnalysis", back_populates="cv_enhancement")
    # Uncomment and add back_populates to ResumeAnalysis model if you want bidirectional navigation
