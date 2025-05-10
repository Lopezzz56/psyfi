# test_ws.py
import asyncio
import websockets

async def main():
    uri = "ws://localhost:8000/ws"
    async with websockets.connect(uri) as websocket:
        await websocket.send("hello!")
        response = await websocket.recv()
        print("🧠 AI:", response)

asyncio.run(main())
