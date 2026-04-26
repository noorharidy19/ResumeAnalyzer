from sqlalchemy.orm import Session
from app.models.message import Message
from app.models.connection import Connection, ConnectionStatus
from app.models.user import User
from app.schemas.message import MessageCreate, MessageResponse
from datetime import datetime
from sqlalchemy import and_, or_, desc

class MessageService:
    @staticmethod
    def create_message(
        sender_id: str,
        receiver_id: str,
        connection_id: str,
        content: str,
        db: Session
    ) -> Message:
        """Create a new message"""
        message = Message(
            sender_id=sender_id,
            receiver_id=receiver_id,
            connection_id=connection_id,
            content=content,
            is_read=False
        )
        db.add(message)
        db.commit()
        db.refresh(message)
        return message
    
    @staticmethod
    def get_chat_history(
        user_id: str,
        other_user_id: str,
        connection_id: str,
        limit: int = 50,
        db: Session = None
    ) -> list[Message]:
        """Get chat history between two users"""
        messages = db.query(Message).filter(
            and_(
                Message.connection_id == connection_id,
                or_(
                    and_(Message.sender_id == user_id, Message.receiver_id == other_user_id),
                    and_(Message.sender_id == other_user_id, Message.receiver_id == user_id)
                )
            )
        ).order_by(Message.created_at.desc()).limit(limit).all()
        
        return list(reversed(messages))
    
    @staticmethod
    def mark_as_read(message_id: str, db: Session) -> Message:
        """Mark a message as read"""
        message = db.query(Message).filter(Message.id == message_id).first()
        if message:
            message.is_read = True
            db.commit()
            db.refresh(message)
        return message
    
    @staticmethod
    def mark_connection_as_read(
        connection_id: str,
        receiver_id: str,
        db: Session
    ) -> int:
        """Mark all unread messages in a connection as read"""
        messages = db.query(Message).filter(
            and_(
                Message.connection_id == connection_id,
                Message.receiver_id == receiver_id,
                Message.is_read == False
            )
        ).all()
        
        count = 0
        for msg in messages:
            msg.is_read = True
            count += 1
        
        db.commit()
        return count
    
    @staticmethod
    def get_unread_count(user_id: str, db: Session) -> int:
        """Get total unread messages count for a user"""
        count = db.query(Message).filter(
            and_(
                Message.receiver_id == user_id,
                Message.is_read == False
            )
        ).count()
        return count
    
    @staticmethod
    def get_unread_count_for_connection(
        connection_id: str,
        receiver_id: str,
        db: Session
    ) -> int:
        """Get unread messages count for a specific connection"""
        count = db.query(Message).filter(
            and_(
                Message.connection_id == connection_id,
                Message.receiver_id == receiver_id,
                Message.is_read == False
            )
        ).count()
        return count
    
    @staticmethod
    def delete_message(message_id: str, db: Session) -> bool:
        """Delete a message"""
        message = db.query(Message).filter(Message.id == message_id).first()
        if message:
            db.delete(message)
            db.commit()
            return True
        return False
