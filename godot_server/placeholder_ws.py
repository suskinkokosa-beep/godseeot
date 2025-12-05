#!/usr/bin/env python3
"""
Placeholder WebSocket server to emulate Godot headless behavior for testing.
Compatible with websockets library >= 11.0
"""
import asyncio
import websockets
import json
import time

clients = set()
entities = {}


async def handler(websocket):
    """Handle WebSocket connections"""
    raw = await websocket.recv()
    try:
        msg = json.loads(raw)
        if msg.get('t') == 'auth_init':
            sub = msg.get('sub', 'anon')
            eid = 'p_' + str(sub)
            entities[eid] = {'pos': [0, 0, 0], 'rot': 0}
            await websocket.send(json.dumps({
                't': 'spawn',
                'id': eid,
                'pos': [0, 0, 0],
                'rot': 0
            }))
    except Exception:
        pass
    
    clients.add(websocket)
    try:
        async for msg in websocket:
            data = json.loads(msg)
            if data.get('t') == 'move':
                eid = list(entities.keys())[0] if entities else 'p_anon'
                st = entities.get(eid, {'pos': [0, 0, 0], 'rot': 0})
                st['pos'][0] += data.get('dx', 0)
                st['pos'][2] += data.get('dz', 0)
                entities[eid] = st
                await websocket.send(json.dumps({
                    't': 'snapshot',
                    'tick': int(time.time()),
                    'players': [{'id': eid, 'pos': st['pos'], 'rot': 0}]
                }))
    finally:
        clients.discard(websocket)


async def main():
    print('Starting Placeholder WS server on 0.0.0.0:8090...')
    async with websockets.serve(handler, '0.0.0.0', 8090):
        print('Placeholder WS server listening on 8090')
        await asyncio.Future()


if __name__ == '__main__':
    asyncio.run(main())
