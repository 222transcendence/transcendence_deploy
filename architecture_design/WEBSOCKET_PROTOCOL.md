# WebSocket Communication Protocol

## 1. Connection Lifecycle
1. **Connect**: `ws://host:port/ws/game/{room_id}/`
2. **Init**: 서버가 두 플레이어의 연결 확인 후 `GAME_START` 메시지 전송.
3. **Loop**: 각 페이즈마다 클라이언트 전송 -> 서버 연산 -> 전체 브로드캐스트.

## 2. Message Formats (JSON)

### Client -> Server
```json
{
  "action": "SUBMIT_CARDS",
  "data": {
    "card_ids": [12, 45, 7],
    "direction": "FORWARD"
  }
}
```

### Server -> Client (Broadcasting)
```json
{
  "type": "PHASE_UPDATE",
  "data": {
    "current_phase": "ATTACK",
    "initiator": "host",
    "distance": 1,
    "last_move_result": {
       "host_val": 5,
       "guest_val": 2
    }
  }
}
```

## 3. Error Handling
- **Timeout**: 특정 시간(예: 30초) 내 액션 미수행 시 '대기(Wait)' 또는 '패배' 처리.
- **Disconnect**: 재접속 유예 시간 부여 후 최종 패배 처리.
