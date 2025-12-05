#!/usr/bin/env python3
"""
Main server for Isleborn Online - единый API сервер
Обслуживает web_frontend и предоставляет API для авторизации, островов, новостей и рейтингов
"""

from flask import Flask, request, jsonify, send_from_directory, abort
from flask_cors import CORS
import os
import json
import bcrypt
import jwt
import secrets
from datetime import datetime, timedelta
from functools import wraps
import psycopg2
from psycopg2.extras import Json, RealDictCursor
import threading
import asyncio

app = Flask(__name__, static_folder='web_frontend', static_url_path='')
CORS(app, origins="*", supports_credentials=True)

app.config['SECRET_KEY'] = os.environ.get('SESSION_SECRET', secrets.token_hex(32))

DATABASE_URL = os.environ.get('DATABASE_URL')

PEARL_PACKAGES = {
    "pearls_100": {"pearls": 100, "price_rub": 99, "bonus": 0},
    "pearls_500": {"pearls": 500, "price_rub": 399, "bonus": 50},
    "pearls_1000": {"pearls": 1000, "price_rub": 699, "bonus": 150},
    "pearls_2500": {"pearls": 2500, "price_rub": 1499, "bonus": 500},
    "pearls_5000": {"pearls": 5000, "price_rub": 2499, "bonus": 1500}
}

def get_conn():
    return psycopg2.connect(DATABASE_URL)

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header[7:]
        
        if not token:
            return jsonify({'error': 'Токен не предоставлен'}), 401
        
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            conn = get_conn()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute('SELECT * FROM users WHERE id = %s', (data['user_id'],))
            current_user = cur.fetchone()
            cur.close()
            conn.close()
            
            if not current_user:
                return jsonify({'error': 'Пользователь не найден'}), 401
            
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Токен истёк'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Неверный токен'}), 401
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        
        return f(current_user, *args, **kwargs)
    return decorated

def admin_required(f):
    @wraps(f)
    def decorated(current_user, *args, **kwargs):
        if not current_user.get('is_admin'):
            return jsonify({'error': 'Требуются права администратора'}), 403
        return f(current_user, *args, **kwargs)
    return decorated

@app.route('/')
def serve_index():
    return send_from_directory('web_frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    if path.startswith('api/') or path.startswith('island') or path.startswith('v2/'):
        return jsonify({'error': 'Not found'}), 404
    if os.path.exists(os.path.join('web_frontend', path)):
        return send_from_directory('web_frontend', path)
    return send_from_directory('web_frontend', 'index.html')

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok', 'service': 'isleborn_api', 'version': '0.1.0'})

@app.route('/api/health', methods=['GET'])
def api_health():
    return jsonify({
        'status': 'ok',
        'services': {
            'web_frontend': True,
            'api_server': True,
            'database': True
        }
    })

@app.route('/api/auth/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        username = data.get('username', '').strip()
        
        if not email or not password or not username:
            return jsonify({'error': 'Заполните все поля'}), 400
        
        if len(password) < 6:
            return jsonify({'error': 'Пароль должен быть минимум 6 символов'}), 400
        
        if len(username) < 3:
            return jsonify({'error': 'Имя игрока должно быть минимум 3 символа'}), 400
        
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute('SELECT id FROM users WHERE email = %s', (email,))
        if cur.fetchone():
            cur.close()
            conn.close()
            return jsonify({'error': 'Email уже зарегистрирован'}), 400
        
        cur.execute('SELECT id FROM users WHERE username = %s', (username,))
        if cur.fetchone():
            cur.close()
            conn.close()
            return jsonify({'error': 'Имя игрока уже занято'}), 400
        
        cur.execute('''
            INSERT INTO users (email, username, password_hash, pearls)
            VALUES (%s, %s, %s, 100)
            RETURNING id, email, username, is_admin, pearls, level, experience, playtime_minutes, pvp_wins, pve_kills, achievements, islands_count
        ''', (email, username, password_hash))
        
        user = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        token = jwt.encode({
            'user_id': user['id'],
            'exp': datetime.utcnow() + timedelta(days=30)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'status': 'success',
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user['username'],
                'is_admin': user['is_admin'],
                'pearls': user['pearls'],
                'level': user['level'],
                'experience': user['experience'],
                'playtime': user['playtime_minutes'],
                'playtime_minutes': user['playtime_minutes'],
                'pvp_wins': user['pvp_wins'],
                'pve_kills': user['pve_kills'],
                'achievements': user['achievements'],
                'islands': user['islands_count'],
                'islands_count': user['islands_count']
            }
        })
        
    except Exception as e:
        app.logger.error(f'Register error: {e}')
        return jsonify({'error': 'Ошибка регистрации'}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        
        if not email or not password:
            return jsonify({'error': 'Заполните все поля'}), 400
        
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute('SELECT * FROM users WHERE email = %s', (email,))
        user = cur.fetchone()
        
        if not user:
            cur.close()
            conn.close()
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            cur.close()
            conn.close()
            return jsonify({'error': 'Неверный email или пароль'}), 401
        
        cur.execute('UPDATE users SET last_login = now() WHERE id = %s', (user['id'],))
        conn.commit()
        cur.close()
        conn.close()
        
        token = jwt.encode({
            'user_id': user['id'],
            'exp': datetime.utcnow() + timedelta(days=30)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'status': 'success',
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user['username'],
                'is_admin': user['is_admin'],
                'pearls': user['pearls'],
                'level': user['level'],
                'experience': user['experience'],
                'playtime': user['playtime_minutes'],
                'playtime_minutes': user['playtime_minutes'],
                'pvp_wins': user['pvp_wins'],
                'pve_kills': user['pve_kills'],
                'achievements': user['achievements'],
                'islands': user['islands_count'],
                'islands_count': user['islands_count']
            }
        })
        
    except Exception as e:
        app.logger.error(f'Login error: {e}')
        return jsonify({'error': 'Ошибка входа'}), 500

@app.route('/api/auth/verify', methods=['POST'])
def verify_token():
    token = None
    if 'Authorization' in request.headers:
        auth_header = request.headers['Authorization']
        if auth_header.startswith('Bearer '):
            token = auth_header[7:]
    
    if not token:
        data = request.get_json() or {}
        token = data.get('token')
    
    if not token:
        return jsonify({'valid': False, 'error': 'Токен не предоставлен'}), 401
    
    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('SELECT id, username, email, is_admin, pearls, level FROM users WHERE id = %s', (data['user_id'],))
        user = cur.fetchone()
        cur.close()
        conn.close()
        
        if user:
            return jsonify({
                'status': 'success',
                'valid': True,
                'sub': str(user['id']),
                'username': user['username'],
                'email': user['email'],
                'user': user
            })
        else:
            return jsonify({'valid': False, 'error': 'Пользователь не найден'}), 401
            
    except jwt.ExpiredSignatureError:
        return jsonify({'valid': False, 'error': 'Токен истёк'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'valid': False, 'error': 'Неверный токен'}), 401

@app.route('/api/auth/validate', methods=['POST'])
def validate_token():
    return verify_token()

@app.route('/api/user/me', methods=['GET'])
@token_required
def get_current_user(current_user):
    return jsonify({
        'id': current_user['id'],
        'email': current_user['email'],
        'username': current_user['username'],
        'is_admin': current_user['is_admin'],
        'pearls': current_user['pearls'],
        'level': current_user['level'],
        'experience': current_user['experience'],
        'playtime': current_user['playtime_minutes'],
        'playtime_minutes': current_user['playtime_minutes'],
        'pvp_wins': current_user['pvp_wins'],
        'pve_kills': current_user['pve_kills'],
        'achievements': current_user['achievements'],
        'islands': current_user['islands_count'],
        'islands_count': current_user['islands_count']
    })

@app.route('/api/user/update', methods=['PUT'])
@token_required
def update_user(current_user):
    try:
        data = request.get_json()
        username = data.get('username', '').strip()
        
        if username and len(username) >= 3:
            conn = get_conn()
            cur = conn.cursor()
            
            cur.execute('SELECT id FROM users WHERE username = %s AND id != %s', (username, current_user['id']))
            if cur.fetchone():
                cur.close()
                conn.close()
                return jsonify({'error': 'Имя игрока уже занято'}), 400
            
            cur.execute('UPDATE users SET username = %s WHERE id = %s', (username, current_user['id']))
            conn.commit()
            cur.close()
            conn.close()
        
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/change-password', methods=['POST'])
@token_required
def change_password(current_user):
    try:
        data = request.get_json()
        current_password = data.get('current_password', '')
        new_password = data.get('new_password', '')
        
        if not current_password or not new_password:
            return jsonify({'error': 'Заполните все поля'}), 400
        
        if len(new_password) < 6:
            return jsonify({'error': 'Новый пароль должен быть минимум 6 символов'}), 400
        
        if not bcrypt.checkpw(current_password.encode('utf-8'), current_user['password_hash'].encode('utf-8')):
            return jsonify({'error': 'Неверный текущий пароль'}), 401
        
        new_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        conn = get_conn()
        cur = conn.cursor()
        cur.execute('UPDATE users SET password_hash = %s WHERE id = %s', (new_hash, current_user['id']))
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/pearls', methods=['GET'])
@token_required
def get_user_pearls(current_user):
    return jsonify({
        'user_id': current_user['id'],
        'pearls': current_user['pearls']
    })

@app.route('/api/stats/online', methods=['GET'])
def get_online_count():
    try:
        conn = get_conn()
        cur = conn.cursor()
        
        five_min_ago = datetime.utcnow() - timedelta(minutes=5)
        cur.execute('DELETE FROM online_users WHERE last_ping < %s', (five_min_ago,))
        cur.execute('SELECT COUNT(*) FROM online_users')
        count = cur.fetchone()[0]
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'online': count})
    except Exception as e:
        return jsonify({'online': 0})

@app.route('/api/stats/ping', methods=['POST'])
@token_required
def ping_online(current_user):
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO online_users (user_id, last_ping)
            VALUES (%s, now())
            ON CONFLICT (user_id) DO UPDATE SET last_ping = now()
        ''', (current_user['id'],))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/news', methods=['GET'])
def get_news():
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT id, title, content, badge, created_at
            FROM news
            ORDER BY created_at DESC
            LIMIT 20
        ''')
        news = cur.fetchall()
        cur.close()
        conn.close()
        
        for item in news:
            if item['created_at']:
                item['created_at'] = item['created_at'].isoformat()
        
        return jsonify(news)
    except Exception as e:
        return jsonify([])

@app.route('/api/news', methods=['POST'])
@token_required
@admin_required
def create_news(current_user):
    try:
        data = request.get_json()
        title = data.get('title', '').strip()
        content = data.get('content', '').strip()
        badge = data.get('badge', 'update')
        
        if not title or not content:
            return jsonify({'error': 'Заполните все поля'}), 400
        
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            INSERT INTO news (title, content, badge, author_id)
            VALUES (%s, %s, %s, %s)
            RETURNING id, title, content, badge, created_at
        ''', (title, content, badge, current_user['id']))
        news_item = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        if news_item['created_at']:
            news_item['created_at'] = news_item['created_at'].isoformat()
        
        return jsonify(news_item)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/news/<int:news_id>', methods=['DELETE'])
@token_required
@admin_required
def delete_news(current_user, news_id):
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute('DELETE FROM news WHERE id = %s', (news_id,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'status': 'ok'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/guides', methods=['GET'])
def get_guides():
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT id, title, icon, description, content, category
            FROM guides
            ORDER BY id
        ''')
        guides = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(guides)
    except Exception as e:
        return jsonify([])

@app.route('/api/guides', methods=['POST'])
@token_required
@admin_required
def create_guide(current_user):
    try:
        data = request.get_json()
        title = data.get('title', '').strip()
        icon = data.get('icon', '📖')
        description = data.get('description', '').strip()
        content = data.get('content', '').strip()
        category = data.get('category', 'beginner')
        
        if not title or not content:
            return jsonify({'error': 'Заполните обязательные поля'}), 400
        
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            INSERT INTO guides (title, icon, description, content, category)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id, title, icon, description, content, category
        ''', (title, icon, description, content, category))
        guide = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify(guide)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/leaderboard', methods=['GET'])
def get_leaderboard():
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute('''
            SELECT username, level, experience, pvp_wins, pve_kills
            FROM users
            WHERE is_admin = FALSE
            ORDER BY level DESC, experience DESC
            LIMIT 100
        ''')
        players = cur.fetchall()
        cur.close()
        conn.close()
        
        result = []
        for i, player in enumerate(players):
            result.append({
                'rank': i + 1,
                'username': player['username'],
                'level': player['level'],
                'score': player['experience'],
                'pvp': player['pvp_wins'],
                'pve': player['pve_kills']
            })
        
        return jsonify(result)
    except Exception as e:
        return jsonify([])

@app.route('/api/packages', methods=['GET'])
def get_packages():
    return jsonify({"packages": PEARL_PACKAGES})

@app.route('/api/payment/purchase', methods=['POST'])
@token_required
def purchase_pearls(current_user):
    data = request.get_json()
    if not data:
        return jsonify({"error": "Неверные данные"}), 400
    
    package_id = data.get("package_id")
    if not package_id or package_id not in PEARL_PACKAGES:
        return jsonify({"error": "Неверный пакет"}), 400
    
    package = PEARL_PACKAGES[package_id]
    total_pearls = package["pearls"] + package["bonus"]
    
    try:
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute('''
            UPDATE users SET pearls = pearls + %s
            WHERE id = %s
            RETURNING pearls
        ''', (total_pearls, current_user['id']))
        
        result = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            "status": "success",
            "package_id": package_id,
            "pearls_added": total_pearls,
            "new_balance": result["pearls"],
            "message": f"Вы получили {total_pearls} жемчужин!"
        })
        
    except Exception as e:
        return jsonify({"error": "Ошибка покупки"}), 500

@app.route('/island/<owner>', methods=['GET'])
def get_island(owner):
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
        """, (owner, owner_name, island.get('level', 1), Json(island)))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        app.logger.warn('DB upsert failed: %s', e)
        path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(island, f, indent=2)
    return jsonify({'status': 'ok', 'owner': owner})

@app.route('/island/<owner>', methods=['PUT'])
def update_island(owner):
    payload = request.get_json(force=True)
    island = payload.get('island')
    if not island:
        return abort(400, 'island payload required')
    
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
        """, (owner, island.get('owner_name', owner), island.get('level', 1), Json(island)))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        app.logger.warn('DB update failed: %s', e)
        path = os.path.join('godot_server', 'islands', f'island_{owner}.json')
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(island, f, indent=2)
    return jsonify({'status': 'ok', 'owner': owner})

@app.route('/v2/account/authenticate/email', methods=['POST'])
def nakama_compatible_auth():
    """Nakama-compatible auth endpoint for Godot client"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')
        create = request.args.get('create', 'false').lower() == 'true'
        
        if not email or not password:
            return jsonify({'error': 'Email and password required'}), 400
        
        conn = get_conn()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute('SELECT * FROM users WHERE email = %s', (email,))
        user = cur.fetchone()
        
        if not user:
            if create:
                username = email.split('@')[0]
                password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                cur.execute('''
                    INSERT INTO users (email, username, password_hash)
                    VALUES (%s, %s, %s)
                    RETURNING *
                ''', (email, username, password_hash))
                user = cur.fetchone()
                conn.commit()
            else:
                cur.close()
                conn.close()
                return jsonify({'error': 'User not found', 'code': 5}), 404
        else:
            if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
                cur.close()
                conn.close()
                return jsonify({'error': 'Invalid credentials', 'code': 4}), 401
        
        cur.execute('UPDATE users SET last_login = now() WHERE id = %s', (user['id'],))
        conn.commit()
        cur.close()
        conn.close()
        
        token = jwt.encode({
            'user_id': user['id'],
            'sub': str(user['id']),
            'username': user['username'],
            'exp': datetime.utcnow() + timedelta(days=30)
        }, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'token': token,
            'username': user['username'],
            'user_id': str(user['id']),
            'created': False
        })
        
    except Exception as e:
        app.logger.error(f'Nakama auth error: {e}')
        return jsonify({'error': str(e)}), 500

@app.after_request
def add_headers(response):
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    return response

@app.route('/api/auth/logout', methods=['POST'])
def logout():
    return jsonify({'status': 'success'})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print("=" * 60)
    print("  Isleborn Online API Server")
    print("=" * 60)
    print(f"  Running on http://0.0.0.0:{port}")
    print("=" * 60)
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
