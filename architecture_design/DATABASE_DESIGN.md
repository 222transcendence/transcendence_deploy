# Database Schema Design

## 1. Entities & Relationships

### User
- `id`: Primary Key
- `username`: Unique
- `wins / losses`: Statistics

### Character
- `id`: Primary Key
- `name`: (e.g., "Magician")
- `base_hp`: Integer
- `base_atk`: Integer
- `base_def`: Integer
- `skills`: JSON (Skill triggers and effects)

### Card (Action Card)
- `id`: Primary Key
- `type`: (MOVE, ATK_SWORD, ATK_GUN, DEF, SPECIAL)
- `value_top`: Integer
- `value_bottom`: Integer

### MatchHistory
- `id`: Primary Key
- `host_user`: FK to User
- `guest_user`: FK to User
- `winner`: FK to User
- `turns_played`: Integer
- `match_data`: JSON (Log of all actions for replay)

## 2. Real-time Session State (Stored in Redis)
실시간 대전 중인 방의 상태는 고속 처리를 위해 Redis에 임시 보관함.
- `room_id`: {
    "phase": "MOVE",
    "host_cards_submitted": [...],
    "guest_cards_submitted": [...],
    "distance": 3,
    "current_turn": 5
  }
