from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.supabase_client import get_db
from uuid import UUID
import uuid as uuid_module

router = APIRouter()

def serialize_value(value):
    """Convert database values to JSON-serializable types"""
    if isinstance(value, UUID):
        return str(value)
    return value

def validate_uuid(value: str) -> str:
    """Validate and return UUID string"""
    try:
        uuid_module.UUID(value)
        return value
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid UUID format: {value}")

@router.post("/to-incident")
def assign_responder(payload: dict, db: Session = Depends(get_db)):
    try:
        responder_id = payload.get("responder_id")
        incident_id = payload.get("incident_id")

        if not responder_id or not incident_id:
            raise HTTPException(status_code=400, detail="Missing IDs")

        # Validate UUIDs
        responder_id = validate_uuid(str(responder_id).strip())
        incident_id = validate_uuid(str(incident_id).strip())

        db.execute(text("""
            UPDATE responders 
            SET status = 'busy', current_incident_id = :inc_id 
            WHERE id = :res_id
        """), {"inc_id": incident_id, "res_id": responder_id})

        db.execute(text("""
            UPDATE incidents 
            SET status = 'in-progress' 
            WHERE id = :inc_id
        """), {"inc_id": incident_id})

        db.commit()
        return {"status": "assigned", "responder_id": responder_id, "incident_id": incident_id}
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/available-responders")
def get_available_responders(db: Session = Depends(get_db)):
    try:
        query = text("""
            SELECT id, name, type, status, last_location_lat, last_location_lng 
            FROM responders 
            WHERE status = 'active'
            ORDER BY name ASC
        """)
        responders = db.execute(query).fetchall()
        
        result = [
            {
                "id": serialize_value(r.id), 
                "name": r.name, 
                "type": r.type,
                "lat": r.last_location_lat, 
                "lng": r.last_location_lng
            } 
            for r in responders
        ]
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.get("/nearby-responders")
def get_nearby_responders(lat: float, lng: float, r_type: str, db: Session = Depends(get_db)):
    try:
        query = text("""
            SELECT id, name, last_location_lat, last_location_lng 
            FROM responders 
            WHERE type = :r_type AND status = 'active'
            AND ABS(last_location_lat - :lat) < 0.05
            AND ABS(last_location_lng - :lng) < 0.05
        """)
        responders = db.execute(query, {"lat": lat, "lng": lng, "r_type": r_type}).fetchall()
        
        return [{"id": serialize_value(r.id), "name": r.name, "lat": r.last_location_lat, "lng": r.last_location_lng} for r in responders]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@router.post("/release/{responder_id}")
def release_responder(responder_id: str, db: Session = Depends(get_db)):
    try:
        responder_id = validate_uuid(responder_id.strip())
        db.execute(text("""
            UPDATE responders 
            SET status = 'active', current_incident_id = NULL 
            WHERE id = :id
        """), {"id": responder_id})
        db.commit()
        return {"status": "released", "responder_id": responder_id}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")