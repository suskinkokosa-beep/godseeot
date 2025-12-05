# Placeholder WebSocket server to emulate Godot headless behavior for testing.
import asyncio, websockets, json, time
clients = set()
entities = {}
async def handler(ws, path):
    raw = await ws.recv()
    try:
        msg = json.loads(raw)
        if msg.get('t') == 'auth_init':
            sub = msg.get('sub','anon')
            eid = 'p_'+str(sub)
            entities[eid] = {'pos':[0,0,0],'rot':0}
            await ws.send(json.dumps({'t':'spawn','id':eid,'pos':[0,0,0],'rot':0}))
    except Exception:
        pass
    clients.add(ws)
    try:
        async for msg in ws:
            data = json.loads(msg)
            if data.get('t') == 'move':
                eid = list(entities.keys())[0] if entities else 'p_anon'
                st = entities.get(eid, {'pos':[0,0,0],'rot':0})
                st['pos'][0] += data.get('dx',0)
                st['pos'][2] += data.get('dz',0)
                entities[eid] = st
                await ws.send(json.dumps({'t':'snapshot','tick':int(time.time()),'players':[{'id':eid,'pos':st['pos'],'rot':0}]}))
    finally:
        clients.remove(ws)

async def main():
    server = await websockets.serve(handler, '0.0.0.0', 8090)
    print('Placeholder WS server listening on 8090')
    await asyncio.Future()

if __name__ == '__main__':
    asyncio.run(main())
