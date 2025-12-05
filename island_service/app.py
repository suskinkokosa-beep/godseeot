from flask import Flask, request, jsonify, abort
import os, json, redis
from urllib.parse import urljoin
import psycopg2
from psycopg2.extras import Json, RealDictCursor

app = Flask(__name__)
REDIS_HOST=os.environ.get('REDIS_HOST','redis')
REDIS_PORT=int(os.environ.get('REDIS_PORT','6379'))
redis_client=redis.Redis(host=REDIS_HOST,port=REDIS_PORT,decode_responses=True)

DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://postgres:postgres@postgres:5432/isleborn')

def get_conn():
    return psycopg2.connect(DATABASE_URL)

@app.route('/island/<owner>', methods=['GET'])
def get_island(owner):
    # Try DB first
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT json_state FROM islands WHERE owner = %s', (owner,))
        row = cur.fetchone()
        cur.close()
        conn.close()
        if row:
            return jsonify(row['json_state'])
    except Exception as e:
        app.logger.warn('DB read failed: %s', e)
    # Fallback to file
    path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return jsonify(json.load(f))
    return abort(404)

@app.route('/island', methods=['POST'])
def create_island():
    payload = request.get_json(force=True)
    owner = payload.get('owner')
    if not owner:
        return abort(400, 'owner required')
    owner_name = payload.get('owner_name', owner)
    island = payload.get('island')
    if not island:
        return abort(400, 'island payload required')
    # upsert into DB
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO islands (owner, owner_name, level, json_state, updated_at)
            VALUES (%s, %s, %s, %s, now())
            ON CONFLICT (owner) DO UPDATE SET
              owner_name = EXCLUDED.owner_name,
              level = EXCLUDED.level,
              json_state = EXCLUDED.json_state,
              updated_at = now();
        """, (owner, owner_name, island.get('level',1), Json(island)))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        app.logger.warn('DB upsert failed: %s', e)
        # fallback to file
        path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(island, f, indent=2)
    return jsonify({'status':'ok','owner':owner})

@app.route('/island/<owner>', methods=['PUT'])
def update_island(owner):
    lock_key=f'lock:island:{owner}'
    if not redis_client.set(lock_key,'1',nx=True,ex=10):
        return jsonify({'status':'busy'}),409

    payload = request.get_json(force=True)
    island = payload.get('island')
    if not island:
        return abort(400, 'island payload required')
    # upsert same as create
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO islands (owner, owner_name, level, json_state, updated_at)
            VALUES (%s, %s, %s, %s, now())
            ON CONFLICT (owner) DO UPDATE SET
              owner_name = EXCLUDED.owner_name,
              level = EXCLUDED.level,
              json_state = EXCLUDED.json_state,
              updated_at = now();
        """, (owner, island.get('owner_name', owner), island.get('level',1), Json(island)))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        app.logger.warn('DB update failed: %s', e)
        path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(island, f, indent=2)
    return jsonify({'status':'ok','owner':owner})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', '5000')))
