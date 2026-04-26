from sqlalchemy.orm import Session
from app.models.connection import Connection, ConnectionStatus
from app.models.user import User
from sqlalchemy import or_

class ConnectionService:
    
    @staticmethod
    def send_connection_request(db: Session, sender_id: str, receiver_id: str):
        """Send a connection request"""
        # Check if request already exists
        existing = db.query(Connection).filter(
            or_(
                (Connection.sender_id == sender_id) & (Connection.receiver_id == receiver_id),
                (Connection.sender_id == receiver_id) & (Connection.receiver_id == sender_id)
            )
        ).first()
        
        if existing:
            return {"error": "Connection request already exists"}
        
        # Check if users exist
        sender = db.query(User).filter(User.id == sender_id).first()
        receiver = db.query(User).filter(User.id == receiver_id).first()
        
        if not sender or not receiver:
            return {"error": "User not found"}
        
        if sender_id == receiver_id:
            return {"error": "Cannot connect to yourself"}
        
        connection = Connection(
            sender_id=sender_id,
            receiver_id=receiver_id,
            status="pending"
        )
        db.add(connection)
        db.commit()
        db.refresh(connection)
        
        return connection
    
    @staticmethod
    def accept_connection_request(db: Session, connection_id: str, user_id: str):
        """Accept a pending connection request"""
        connection = db.query(Connection).filter(
            Connection.id == connection_id,
            Connection.receiver_id == user_id,
            Connection.status == "pending"
        ).first()
        
        if not connection:
            return {"error": "Connection request not found"}
        
        connection.status = "accepted"
        db.commit()
        db.refresh(connection)
        
        return connection
    
    @staticmethod
    def reject_connection_request(db: Session, connection_id: str, user_id: str):
        """Reject a pending connection request"""
        connection = db.query(Connection).filter(
            Connection.id == connection_id,
            Connection.receiver_id == user_id,
            Connection.status == "pending"
        ).first()
        
        if not connection:
            return {"error": "Connection request not found"}
        
        connection.status = "rejected"
        db.commit()
        db.refresh(connection)
        
        return connection
    
    @staticmethod
    def get_pending_requests(db: Session, user_id: str):
        """Get all pending connection requests for a user"""
        requests = db.query(Connection).filter(
            Connection.receiver_id == user_id,
            Connection.status == "pending"
        ).all()
        
        return requests
    
    @staticmethod
    def get_all_connections(db: Session, user_id: str):
        """Get all accepted connections for a user"""
        connections = db.query(Connection).filter(
            or_(
                (Connection.sender_id == user_id),
                (Connection.receiver_id == user_id)
            ),
            Connection.status == "accepted"
        ).all()
        
        return connections
    
    @staticmethod
    def get_connection_status(db: Session, user1_id: str, user2_id: str):
        """Get connection status between two users"""
        connection = db.query(Connection).filter(
            or_(
                (Connection.sender_id == user1_id) & (Connection.receiver_id == user2_id),
                (Connection.sender_id == user2_id) & (Connection.receiver_id == user1_id)
            )
        ).first()
        
        return connection
