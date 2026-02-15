"""WebSocket endpoints for real-time order tracking."""
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Dict
from uuid import UUID

router = APIRouter(tags=["WebSocket"])


class ConnectionManager:
    """Manage active WebSocket connections per order."""

    def __init__(self):
        self.active_connections: Dict[str, list[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, channel: str):
        await websocket.accept()
        if channel not in self.active_connections:
            self.active_connections[channel] = []
        self.active_connections[channel].append(websocket)

    def disconnect(self, websocket: WebSocket, channel: str):
        if channel in self.active_connections:
            self.active_connections[channel].remove(websocket)
            if not self.active_connections[channel]:
                del self.active_connections[channel]

    async def broadcast(self, channel: str, message: dict):
        if channel in self.active_connections:
            disconnected = []
            for connection in self.active_connections[channel]:
                try:
                    await connection.send_json(message)
                except Exception:
                    disconnected.append(connection)
            for conn in disconnected:
                self.disconnect(conn, channel)


manager = ConnectionManager()


@router.websocket("/ws/orders/{order_id}")
async def order_tracking(websocket: WebSocket, order_id: str):
    """WebSocket for real-time order status updates."""
    channel = f"order:{order_id}"
    await manager.connect(websocket, channel)
    try:
        while True:
            data = await websocket.receive_text()
            # Client can send location updates (delivery partner)
            try:
                msg = json.loads(data)
                if msg.get("type") == "location_update":
                    await manager.broadcast(channel, {
                        "type": "location_update",
                        "latitude": msg.get("latitude"),
                        "longitude": msg.get("longitude"),
                        "timestamp": msg.get("timestamp"),
                    })
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel)


@router.websocket("/ws/vendor/{vendor_id}")
async def vendor_notifications(websocket: WebSocket, vendor_id: str):
    """WebSocket for vendor to receive new order notifications."""
    channel = f"vendor:{vendor_id}"
    await manager.connect(websocket, channel)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, channel)


# Helper to notify from order service
async def notify_order_update(order_id: str, status: str, data: dict = None):
    """Send order status update to connected clients."""
    message = {
        "type": "order_status",
        "order_id": order_id,
        "status": status,
        **(data or {}),
    }
    await manager.broadcast(f"order:{order_id}", message)


async def notify_vendor_new_order(vendor_id: str, order_data: dict):
    """Notify vendor of a new order."""
    message = {
        "type": "new_order",
        **order_data,
    }
    await manager.broadcast(f"vendor:{vendor_id}", message)
