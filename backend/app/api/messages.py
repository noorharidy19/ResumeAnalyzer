from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.auth import get_current_user
from app.schemas.message import MessageCreate, MessageResponse, ChatHistoryResponse
from app.services.message import MessageService
from app.services.notification import NotificationService
from app.models.connection import Connection, ConnectionStatus
from app.models.user import User

router = APIRouter(
    prefix="/api/messages",
    tags=["messages"],
    dependencies=[Depends(get_current_user)]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/send/{connection_id}")
def send_message(
    connection_id: str,
    message_data: MessageCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message to another user"""
    user_id = current_user.get("id")
    
    # Verify connection exists and is accepted
    connection = db.query(Connection).filter(
        Connection.id == connection_id
    ).first()
    
    if not connection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connection not found"
        )
    
    if connection.status != ConnectionStatus.ACCEPTED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Connection must be accepted to send messages"
        )
    
    # Verify user is part of this connection
    if connection.sender_id != user_id and connection.receiver_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not part of this connection"
        )
    
    # Determine sender and receiver
    if connection.sender_id == user_id:
        receiver_id = connection.receiver_id
    else:
        receiver_id = connection.sender_id
    
    # Create message
    message = MessageService.create_message(
        sender_id=user_id,
        receiver_id=receiver_id,
        connection_id=connection_id,
        content=message_data.content,
        db=db
    )
    
    # Create notification for receiver
    NotificationService.create_notification(
        user_id=receiver_id,
        notification_type="message",
        related_id=message.id,
        triggered_by_id=user_id,
        db=db
    )
    
    # Get sender and receiver info
    sender = db.query(User).filter(User.id == user_id).first()
    receiver = db.query(User).filter(User.id == receiver_id).first()
    
    return {
        "id": message.id,
        "sender_id": message.sender_id,
        "receiver_id": message.receiver_id,
        "content": message.content,
        "is_read": message.is_read,
        "created_at": message.created_at,
        "updated_at": message.updated_at,
        "sender": {
            "id": sender.id,
            "name": sender.name,
            "email": sender.email
        } if sender else None,
        "receiver": {
            "id": receiver.id,
            "name": receiver.name,
            "email": receiver.email
        } if receiver else None
    }

@router.get("/chat/{connection_id}")
async def get_chat_history(
    connection_id: str,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get chat history for a connection"""
    user_id = current_user.get("id")
    
    # Verify connection exists and is accepted
    connection = db.query(Connection).filter(
        Connection.id == connection_id
    ).first()
    
    if not connection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connection not found"
        )
    
    if connection.status != ConnectionStatus.ACCEPTED:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Connection must be accepted to view messages"
        )
    
    # Verify user is part of this connection
    if connection.sender_id != user_id and connection.receiver_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not part of this connection"
        )
    
    # Determine other user
    if connection.sender_id == user_id:
        other_user_id = connection.receiver_id
    else:
        other_user_id = connection.sender_id
    
    # Get messages
    messages = MessageService.get_chat_history(
        user_id=user_id,
        other_user_id=other_user_id,
        connection_id=connection_id,
        limit=limit,
        db=db
    )
    
    # Get other user info
    other_user = db.query(User).filter(User.id == other_user_id).first()
    
    # Get unread count
    unread_count = MessageService.get_unread_count_for_connection(
        connection_id=connection_id,
        receiver_id=user_id,
        db=db
    )
    
    # Mark messages as read
    MessageService.mark_connection_as_read(
        connection_id=connection_id,
        receiver_id=user_id,
        db=db
    )
    
    messages_response = []
    for msg in messages:
        sender = db.query(User).filter(User.id == msg.sender_id).first()
        receiver = db.query(User).filter(User.id == msg.receiver_id).first()
        
        messages_response.append({
            "id": msg.id,
            "sender_id": msg.sender_id,
            "receiver_id": msg.receiver_id,
            "content": msg.content,
            "is_read": msg.is_read,
            "created_at": msg.created_at,
            "updated_at": msg.updated_at,
            "sender": {
                "id": sender.id,
                "name": sender.name,
                "email": sender.email
            } if sender else None,
            "receiver": {
                "id": receiver.id,
                "name": receiver.name,
                "email": receiver.email
            } if receiver else None
        })
    
    return {
        "messages": messages_response,
        "other_user": {
            "id": other_user.id,
            "name": other_user.name,
            "email": other_user.email
        } if other_user else None,
        "unread_count": unread_count
    }

@router.get("/unread-count")
async def get_unread_count(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get total unread messages count"""
    user_id = current_user.get("id")
    count = MessageService.get_unread_count(user_id, db)
    return {"unread_count": count}

@router.get("/unread-count/{connection_id}")
async def get_unread_count_for_connection(
    connection_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get unread messages count for a specific connection (without marking as read)"""
    user_id = current_user.get("id")
    count = MessageService.get_unread_count_for_connection(connection_id, user_id, db)
    return {"unread_count": count}

@router.patch("/{message_id}/read")
async def mark_as_read(
    message_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a message as read"""
    message = MessageService.mark_as_read(message_id, db)
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    return {"status": "marked as read"}

@router.delete("/{message_id}")
async def delete_message(
    message_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a message"""
    if not MessageService.delete_message(message_id, db):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    return {"status": "message deleted"}
