from sqlalchemy.orm import Session
from app.models.user import User

class UserService:
    
    @staticmethod
    def get_all_users(db: Session, exclude_user_id: str = None):
        """Get all users, optionally excluding a specific user"""
        query = db.query(User)
        
        if exclude_user_id:
            query = query.filter(User.id != exclude_user_id)
        
        return query.all()
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: str):
        """Get a user by ID"""
        return db.query(User).filter(User.id == user_id).first()
    
    @staticmethod
    def search_users(db: Session, search_query: str, exclude_user_id: str = None):
        """Search users by name or email"""
        query = db.query(User).filter(
            User.name.ilike(f"%{search_query}%") | 
            User.email.ilike(f"%{search_query}%")
        )
        
        if exclude_user_id:
            query = query.filter(User.id != exclude_user_id)
        
        return query.all()
