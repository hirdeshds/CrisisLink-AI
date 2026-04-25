"""
Seed test responders into the database
"""
import os
import uuid
from sqlalchemy import text
from app.db.supabase_client import SessionLocal

def seed_responders():
    db = SessionLocal()
    try:
        # Check if responders table exists and has data
        result = db.execute(text("SELECT COUNT(*) as count FROM responders WHERE status = 'active'"))
        count = result.scalar()
        
        if count and count > 0:
            print(f"✅ {count} active responders already exist")
            return
        
        # Insert test responders with UUID
        responders = [
            (str(uuid.uuid4()), "Officer John", "POLICE", "active", 28.769, 77.506),
            (str(uuid.uuid4()), "Paramedic Sarah", "AMBULANCE", "active", 28.770, 77.507),
            (str(uuid.uuid4()), "Firefighter Mike", "FIRE", "active", 28.768, 77.505),
            (str(uuid.uuid4()), "Officer David", "POLICE", "active", 28.771, 77.508),
            (str(uuid.uuid4()), "Paramedic Lisa", "AMBULANCE", "active", 28.767, 77.504),
        ]
        
        for responder in responders:
            db.execute(text("""
                INSERT INTO responders (id, name, type, status, last_location_lat, last_location_lng)
                VALUES (:id, :name, :type, :status, :lat, :lng)
                ON CONFLICT (id) DO UPDATE SET
                    status = :status,
                    last_location_lat = :lat,
                    last_location_lng = :lng
            """), {
                "id": responder[0],
                "name": responder[1],
                "type": responder[2],
                "status": responder[3],
                "lat": responder[4],
                "lng": responder[5],
            })
        
        db.commit()
        print(f"✅ Seeded {len(responders)} test responders")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Error seeding responders: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_responders()
