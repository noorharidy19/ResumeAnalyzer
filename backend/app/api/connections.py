from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.connection import ConnectionService
from app.services.notification import NotificationService
from app.schemas.connection import ConnectionCreate, ConnectionUpdate, ConnectionResponse, PendingRequestsResponse
from app.services.auth import get_current_user

router = APIRouter(prefix="/api/connections", tags=["connections"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/request")
def send_connection_request(
    request_data: ConnectionCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a connection request to another user"""
    try:
        print(f"Current user: {current_user}")
        print(f"Request data: {request_data}")
        print(f"Receiver ID: {request_data.receiver_id}")
        
        result = ConnectionService.send_connection_request(
            db, 
            current_user["id"], 
            request_data.receiver_id
        )
        
        print(f"Service result: {result}")
        
        if isinstance(result, dict) and "error" in result:
            print(f"Service error: {result['error']}")
            raise HTTPException(status_code=400, detail=result["error"])
        
        # Create notification for receiver
        NotificationService.create_notification(
            user_id=result.receiver_id,
            notification_type="connection_request",
            related_id=str(result.id),
            triggered_by_id=result.sender_id,
            db=db
        )
        
        response_data = {
            "id": str(result.id),
            "sender_id": str(result.sender_id),
            "receiver_id": str(result.receiver_id),
            "status": str(result.status),
            "created_at": result.created_at.isoformat(),
            "updated_at": result.updated_at.isoformat()
        }
        
        print(f"Response data: {response_data}")
        return JSONResponse(content=response_data)
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in send_connection_request: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.put("/{connection_id}/accept")
def accept_connection(
    connection_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Accept a connection request"""
    try:
        result = ConnectionService.accept_connection_request(
            db,
            connection_id,
            current_user["id"]
        )
        
        if isinstance(result, dict) and "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        
        # Create notification for sender (connection accepted)
        NotificationService.create_notification(
            user_id=result.sender_id,
            notification_type="connection_accepted",
            related_id=str(result.id),
            triggered_by_id=result.receiver_id,
            db=db
        )
        
        response_data = {
            "message": "Connection accepted",
            "connection": {
                "id": str(result.id),
                "sender_id": str(result.sender_id),
                "receiver_id": str(result.receiver_id),
                "status": result.status,
                "created_at": result.created_at.isoformat(),
                "updated_at": result.updated_at.isoformat()
            }
        }
        return JSONResponse(content=response_data)
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in accept_connection: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.put("/{connection_id}/reject")
def reject_connection(
    connection_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reject a connection request"""
    try:
        result = ConnectionService.reject_connection_request(
            db,
            connection_id,
            current_user["id"]
        )
        
        if isinstance(result, dict) and "error" in result:
            raise HTTPException(status_code=400, detail=result["error"])
        
        return JSONResponse(content={"message": "Connection rejected"})
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in reject_connection: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.get("/pending-requests")
def get_pending_requests(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all pending connection requests"""
    try:
        requests = ConnectionService.get_pending_requests(db, current_user["id"])
        
        request_list = []
        for r in requests:
            request_list.append({
                "id": str(r.id),
                "sender_id": str(r.sender_id),
                "receiver_id": str(r.receiver_id),
                "status": r.status,
                "created_at": r.created_at.isoformat(),
                "updated_at": r.updated_at.isoformat(),
                "sender": {
                    "id": str(r.sender.id),
                    "name": r.sender.name,
                    "email": r.sender.email,
                    "phone_number": r.sender.phone_number,
                    "role": r.sender.role
                } if r.sender else None,
                "receiver": {
                    "id": str(r.receiver.id),
                    "name": r.receiver.name,
                    "email": r.receiver.email,
                    "phone_number": r.receiver.phone_number,
                    "role": r.receiver.role
                } if r.receiver else None
            })
        
        return JSONResponse(content={
            "pending_count": len(requests),
            "requests": request_list
        })
    except Exception as e:
        print(f"Error in get_pending_requests: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.get("/my-connections")
def get_my_connections(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all accepted connections"""
    try:
        connections = ConnectionService.get_all_connections(db, current_user["id"])
        
        conn_list = []
        for c in connections:
            conn_list.append({
                "id": str(c.id),
                "sender_id": str(c.sender_id),
                "receiver_id": str(c.receiver_id),
                "status": c.status,
                "created_at": c.created_at.isoformat(),
                "updated_at": c.updated_at.isoformat(),
                "sender": {
                    "id": str(c.sender.id),
                    "name": c.sender.name,
                    "email": c.sender.email,
                    "phone_number": c.sender.phone_number,
                    "role": c.sender.role
                } if c.sender else None,
                "receiver": {
                    "id": str(c.receiver.id),
                    "name": c.receiver.name,
                    "email": c.receiver.email,
                    "phone_number": c.receiver.phone_number,
                    "role": c.receiver.role
                } if c.receiver else None
            })
        
        return JSONResponse(content=conn_list)
    except Exception as e:
        print(f"Error in get_my_connections: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@router.get("/status/{other_user_id}")
def get_connection_status(
    other_user_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get connection status with another user"""
    try:
        connection = ConnectionService.get_connection_status(
            db,
            current_user["id"],
            other_user_id
        )
        
        if not connection:
            return JSONResponse(content={"status": "none"})
        
        return JSONResponse(content={
            "status": connection.status,
            "id": str(connection.id),
            "sender_id": str(connection.sender_id),
            "receiver_id": str(connection.receiver_id)
        })
    except Exception as e:
        print(f"Error in get_connection_status: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")
