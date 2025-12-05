#!/usr/bin/env python3
"""
Unified server for Isleborn Online
Serves web frontend and provides API endpoints for authentication and payments
"""

from flask import Flask, request, jsonify, send_from_directory, abort
from flask_cors import CORS
import os
import json
import hashlib
import secrets
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__, static_folder='web_frontend', static_url_path='')
CORS(app)

DATABASE_URL = os.getenv("DATABASE_URL")

PEARL_PACKAGES = {
    "pearls_100": {"pearls": 100, "price_rub": 99, "bonus": 0},
    "pearls_500": {"pearls": 500, "price_rub": 399, "bonus": 50},
    "pearls_1000": {"pearls": 1000, "price_rub": 699, "bonus": 150},
    "pearls_2500": {"pearls": 2500, "price_rub": 1499, "bonus": 500},
    "pearls_5000": {"pearls": 5000, "price_rub": 2499, "bonus": 1500}
}

active_tokens = {}

def get_db():
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)

def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def generate_token() -> str:
    return secrets.token_hex(32)

@app.route('/')
def serve_index():
    return send_from_directory('web_frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    try:
        return send_from_directory('web_frontend', path)
    except:
        return send_from_directory('web_frontend', 'index.html')

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "isleborn_server"})

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Invalid data"}), 400
    
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    username = data.get("username", "").strip()
    
    if not email or not password or not username:
        return jsonify({"error": "Please fill all fields"}), 400
    
    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters"}), 400
    
    if len(username) < 2:
        return jsonify({"error": "Username must be at least 2 characters"}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            conn.close()
            return jsonify({"error": "User with this email already exists"}), 400
        
        user_id = f"user_{secrets.token_hex(8)}"
        password_hash = hash_password(password)
        
        cur.execute("""
            INSERT INTO users (id, username, email, password_hash, pearls, level, playtime, islands, achievements)
            VALUES (%s, %s, %s, %s, 100, 1, 0, 1, 0)
            RETURNING id, username, email, pearls, level, playtime, islands, achievements
        """, (user_id, username, email, password_hash))
        
        user = cur.fetchone()
        conn.commit()
        
        token = generate_token()
        active_tokens[token] = user_id
        
        conn.close()
        
        return jsonify({
            "status": "success",
            "token": token,
            "user": {
                "id": user["id"],
                "username": user["username"],
                "email": user["email"],
                "pearls": user["pearls"],
                "level": user["level"],
                "playtime": user["playtime"],
                "islands": user["islands"],
                "achievements": user["achievements"]
            }
        })
        
    except Exception as e:
        print(f"Register error: {e}")
        return jsonify({"error": "Registration error"}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Invalid data"}), 400
    
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    
    if not email or not password:
        return jsonify({"error": "Enter email and password"}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        password_hash = hash_password(password)
        
        cur.execute("""
            SELECT id, username, email, pearls, level, playtime, islands, achievements
            FROM users WHERE email = %s AND password_hash = %s
        """, (email, password_hash))
        
        user = cur.fetchone()
        conn.close()
        
        if not user:
            return jsonify({"error": "Invalid email or password"}), 401
        
        token = generate_token()
        active_tokens[token] = user["id"]
        
        return jsonify({
            "status": "success",
            "token": token,
            "user": {
                "id": user["id"],
                "username": user["username"],
                "email": user["email"],
                "pearls": user["pearls"],
                "level": user["level"],
                "playtime": user["playtime"],
                "islands": user["islands"],
                "achievements": user["achievements"]
            }
        })
        
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({"error": "Login error"}), 500

@app.route('/api/auth/verify', methods=['POST'])
def verify_token():
    data = request.get_json()
    token = data.get("token") if data else None
    
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    
    if not token or token not in active_tokens:
        return jsonify({"error": "Invalid token"}), 401
    
    user_id = active_tokens[token]
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("""
            SELECT id, username, email, pearls, level, playtime, islands, achievements
            FROM users WHERE id = %s
        """, (user_id,))
        
        user = cur.fetchone()
        conn.close()
        
        if not user:
            del active_tokens[token]
            return jsonify({"error": "User not found"}), 401
        
        return jsonify({
            "status": "success",
            "user": {
                "id": user["id"],
                "username": user["username"],
                "email": user["email"],
                "pearls": user["pearls"],
                "level": user["level"],
                "playtime": user["playtime"],
                "islands": user["islands"],
                "achievements": user["achievements"]
            }
        })
        
    except Exception as e:
        print(f"Verify error: {e}")
        return jsonify({"error": "Verification error"}), 500

@app.route('/api/auth/logout', methods=['POST'])
def logout():
    data = request.get_json()
    token = data.get("token") if data else None
    
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    
    if token and token in active_tokens:
        del active_tokens[token]
    
    return jsonify({"status": "success"})

@app.route('/api/packages', methods=['GET'])
def get_packages():
    return jsonify({"packages": PEARL_PACKAGES})

@app.route('/api/user/pearls', methods=['GET'])
def get_user_pearls():
    auth_header = request.headers.get("Authorization", "")
    token = auth_header[7:] if auth_header.startswith("Bearer ") else None
    
    if not token or token not in active_tokens:
        return jsonify({"error": "Authorization required"}), 401
    
    user_id = active_tokens[token]
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("SELECT pearls FROM users WHERE id = %s", (user_id,))
        user = cur.fetchone()
        conn.close()
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        return jsonify({
            "user_id": user_id,
            "pearls": user["pearls"]
        })
        
    except Exception as e:
        print(f"Get pearls error: {e}")
        return jsonify({"error": "Error getting balance"}), 500

@app.route('/api/payment/purchase', methods=['POST'])
def purchase_pearls():
    auth_header = request.headers.get("Authorization", "")
    token = auth_header[7:] if auth_header.startswith("Bearer ") else None
    
    if not token or token not in active_tokens:
        return jsonify({"error": "Authorization required"}), 401
    
    user_id = active_tokens[token]
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Invalid data"}), 400
    
    package_id = data.get("package_id")
    
    if not package_id or package_id not in PEARL_PACKAGES:
        return jsonify({"error": "Invalid package"}), 400
    
    package = PEARL_PACKAGES[package_id]
    total_pearls = package["pearls"] + package["bonus"]
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("""
            UPDATE users SET pearls = pearls + %s, updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING pearls
        """, (total_pearls, user_id))
        
        result = cur.fetchone()
        conn.commit()
        conn.close()
        
        if not result:
            return jsonify({"error": "User not found"}), 404
        
        return jsonify({
            "status": "success",
            "package_id": package_id,
            "pearls_added": total_pearls,
            "new_balance": result["pearls"],
            "message": f"You received {total_pearls} pearls!"
        })
        
    except Exception as e:
        print(f"Purchase error: {e}")
        return jsonify({"error": "Purchase error"}), 500

@app.route('/island/<owner>', methods=['GET'])
def get_island(owner):
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('SELECT json_state FROM islands WHERE owner = %s', (owner,))
        row = cur.fetchone()
        cur.close()
        conn.close()
        if row:
            return jsonify(row['json_state'])
    except Exception as e:
        print(f'DB read failed: {e}')
    
    path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return jsonify(json.load(f))
    return abort(404)

@app.route('/island', methods=['POST'])
def create_island():
    from psycopg2.extras import Json
    payload = request.get_json(force=True)
    owner = payload.get('owner')
    if not owner:
        return abort(400, 'owner required')
    owner_name = payload.get('owner_name', owner)
    island = payload.get('island')
    if not island:
        return abort(400, 'island payload required')
    try:
        conn = get_db()
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
        print(f'DB upsert failed: {e}')
        path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(island, f, indent=2)
    return jsonify({'status':'ok','owner':owner})

@app.route('/island/<owner>', methods=['PUT'])
def update_island(owner):
    from psycopg2.extras import Json
    payload = request.get_json(force=True)
    island = payload.get('island')
    if not island:
        return abort(400, 'island payload required')
    try:
        conn = get_db()
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
        print(f'DB update failed: {e}')
        path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(island, f, indent=2)
    return jsonify({'status':'ok','owner':owner})

if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
