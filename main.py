#!/usr/bin/env python3
"""
Unified server for Isleborn Online
Serves web frontend and provides API endpoints for authentication, payments, and game services
"""

from flask import Flask, request, jsonify, send_from_directory, abort
from flask_cors import CORS
import os
import json
import bcrypt
import jwt
import secrets
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import RealDictCursor, Json
from functools import wraps

app = Flask(__name__, static_folder='web_frontend', static_url_path='')
CORS(app, origins="*", supports_credentials=True)

DATABASE_URL = os.getenv("DATABASE_URL")
JWT_SECRET = os.environ.get('JWT_SECRET', secrets.token_hex(32))

PEARL_PACKAGES = {
    "pearls_100": {"pearls": 100, "price_rub": 99, "bonus": 0},
    "pearls_500": {"pearls": 500, "price_rub": 399, "bonus": 50},
    "pearls_1000": {"pearls": 1000, "price_rub": 699, "bonus": 150},
    "pearls_2500": {"pearls": 2500, "price_rub": 1499, "bonus": 500},
    "pearls_5000": {"pearls": 5000, "price_rub": 2499, "bonus": 1500}
}

def get_db():
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)

def get_user_by_token(token):
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            SELECT u.* FROM users u
            JOIN sessions s ON u.id = s.user_id
            WHERE s.token = %s AND s.expires_at > now()
        ''', (token,))
        user = cur.fetchone()
        cur.close()
        conn.close()
        return dict(user) if user else None
    except Exception as e:
        app.logger.error(f'get_user_by_token error: {e}')
        return None

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            token = auth_header[7:]
        else:
            data = request.get_json(silent=True)
            token = data.get('token') if data else None
        
        if not token:
            return jsonify({'error': 'Требуется авторизация'}), 401
        
        user = get_user_by_token(token)
        if not user:
            return jsonify({'error': 'Недействительный токен'}), 401
        
        request.current_user = user
        return f(*args, **kwargs)
    return decorated

def require_admin(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Bearer '):
            token = auth_header[7:]
        else:
            data = request.get_json(silent=True)
            token = data.get('token') if data else None
        
        if not token:
            return jsonify({'error': 'Требуется авторизация'}), 401
        
        user = get_user_by_token(token)
        if not user:
            return jsonify({'error': 'Недействительный токен'}), 401
        
        if not user.get('is_admin'):
            return jsonify({'error': 'Требуются права администратора'}), 403
        
        request.current_user = user
        return f(*args, **kwargs)
    return decorated

@app.route('/')
def serve_index():
    return send_from_directory('web_frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    try:
        if os.path.exists(os.path.join('web_frontend', path)):
            return send_from_directory('web_frontend', path)
        return send_from_directory('web_frontend', 'index.html')
    except:
        return send_from_directory('web_frontend', 'index.html')

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "isleborn_server"})

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Неверные данные"}), 400
    
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    username = data.get("username", "").strip()
    
    if not email or not password or not username:
        return jsonify({"error": "Заполните все поля"}), 400
    
    if len(password) < 6:
        return jsonify({"error": "Пароль должен быть минимум 6 символов"}), 400
    
    if len(username) < 2:
        return jsonify({"error": "Имя должно быть минимум 2 символа"}), 400
    
    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            conn.close()
            return jsonify({"error": "Пользователь с таким email уже существует"}), 400
        
        cur.execute("""
            INSERT INTO users (email, password_hash, username, pearls, level, experience, playtime, achievements)
            VALUES (%s, %s, %s, 100, 1, 0, 0, 0)
            RETURNING id, email, username, pearls, level, experience, playtime, achievements, is_admin
        """, (email, password_hash, username))
        
        user = cur.fetchone()
        
        token = secrets.token_urlsafe(32)
        cur.execute('''
            INSERT INTO sessions (user_id, token)
            VALUES (%s, %s)
        ''', (user['id'], token))
        
        cur.execute('''
            INSERT INTO leaderboard (user_id, score)
            VALUES (%s, 0)
            ON CONFLICT (user_id) DO NOTHING
        ''', (user['id'],))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            "status": "success",
            "token": token,
            "user": dict(user)
        })
        
    except Exception as e:
        print(f"Register error: {e}")
        return jsonify({"error": "Ошибка регистрации"}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Неверные данные"}), 400
    
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    
    if not email or not password:
        return jsonify({"error": "Введите email и пароль"}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        
        if not user:
            conn.close()
            return jsonify({"error": "Неверный email или пароль"}), 401
        
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            conn.close()
            return jsonify({"error": "Неверный email или пароль"}), 401
        
        token = secrets.token_urlsafe(32)
        cur.execute('''
            INSERT INTO sessions (user_id, token)
            VALUES (%s, %s)
        ''', (user['id'], token))
        
        cur.execute('''
            INSERT INTO online_users (user_id, last_seen)
            VALUES (%s, now())
            ON CONFLICT (user_id) DO UPDATE SET last_seen = now()
        ''', (user['id'],))
        
        conn.commit()
        conn.close()
        
        user_data = dict(user)
        del user_data['password_hash']
        
        return jsonify({
            "status": "success",
            "token": token,
            "user": user_data
        })
        
    except Exception as e:
        print(f"Login error: {e}")
        return jsonify({"error": "Ошибка входа"}), 500

@app.route('/api/auth/verify', methods=['POST'])
def verify_token():
    data = request.get_json()
    token = data.get("token") if data else None
    
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    
    if not token:
        return jsonify({"error": "Токен не предоставлен"}), 400
    
    user = get_user_by_token(token)
    if not user:
        return jsonify({"error": "Недействительный токен"}), 401
    
    user_data = dict(user)
    if 'password_hash' in user_data:
        del user_data['password_hash']
    
    return jsonify({"status": "success", "user": user_data})

@app.route('/api/auth/logout', methods=['POST'])
def logout():
    data = request.get_json()
    token = data.get("token") if data else None
    
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    
    if token:
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute('DELETE FROM sessions WHERE token = %s', (token,))
            conn.commit()
            conn.close()
        except Exception as e:
            print(f"Logout error: {e}")
    
    return jsonify({"status": "success"})

@app.route('/v2/rpc/validate_session', methods=['POST'])
def validate_session():
    """Gateway token validation endpoint (Nakama-compatible)"""
    data = request.get_json(force=True)
    token = data.get('token', '')
    
    if not token:
        return jsonify({'valid': False, 'error': 'no token'}), 400
    
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        user_id = payload.get('sub')
        username = payload.get('username', '')
        
        conn = get_db()
        cur = conn.cursor()
        cur.execute('SELECT 1 FROM sessions WHERE token = %s', (token,))
        session = cur.fetchone()
        cur.close()
        conn.close()
        
        if not session:
            return jsonify({'valid': False, 'error': 'session not found'}), 401
        
        return jsonify({
            'valid': True,
            'sub': user_id,
            'username': username
        })
    except jwt.ExpiredSignatureError:
        return jsonify({'valid': False, 'error': 'token expired'}), 401
    except jwt.InvalidTokenError as e:
        return jsonify({'valid': False, 'error': str(e)}), 401
    except Exception as e:
        print(f'Validate session error: {e}')
        return jsonify({'valid': False, 'error': 'validation failed'}), 500

@app.route('/v2/account/authenticate/email', methods=['POST'])
def nakama_compat_auth():
    data = request.get_json(force=True)
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')
    create = request.args.get('create', 'false').lower() == 'true'
    
    if not email or not password:
        return jsonify({'error': 'email and password required'}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute('SELECT * FROM users WHERE email = %s', (email,))
        user = cur.fetchone()
        
        if not user:
            if create:
                password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                username = email.split('@')[0]
                cur.execute('''
                    INSERT INTO users (email, password_hash, username, pearls, level)
                    VALUES (%s, %s, %s, 100, 1)
                    RETURNING id, email, username
                ''', (email, password_hash, username))
                user = cur.fetchone()
                conn.commit()
            else:
                cur.close()
                conn.close()
                return jsonify({'error': 'user not found'}), 404
        else:
            if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
                cur.close()
                conn.close()
                return jsonify({'error': 'invalid credentials'}), 401
        
        expires_at = datetime.utcnow() + timedelta(days=7)
        token_payload = {
            'sub': str(user['id']),
            'username': user['username'],
            'email': user['email'],
            'exp': expires_at.timestamp()
        }
        token = jwt.encode(token_payload, JWT_SECRET, algorithm='HS256')
        
        cur.execute('''
            INSERT INTO sessions (user_id, token, expires_at)
            VALUES (%s, %s, %s)
        ''', (user['id'], token, expires_at))
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            'token': token,
            'username': user['username'],
            'user_id': str(user['id'])
        })
    except Exception as e:
        print(f'Nakama compat auth error: {e}')
        return jsonify({'error': 'auth failed'}), 500

@app.route('/api/packages', methods=['GET'])
def get_packages():
    return jsonify({"packages": PEARL_PACKAGES})

@app.route('/api/user/pearls', methods=['GET'])
@require_auth
def get_user_pearls():
    user = request.current_user
    return jsonify({
        "user_id": user['id'],
        "pearls": user.get('pearls', 0)
    })

@app.route('/api/user/profile', methods=['GET'])
@require_auth
def get_profile():
    user = dict(request.current_user)
    if 'password_hash' in user:
        del user['password_hash']
    return jsonify({'user': user})

@app.route('/api/user/profile', methods=['PUT'])
@require_auth
def update_profile():
    data = request.get_json(force=True)
    user = request.current_user
    
    username = data.get('username', '').strip()
    if username and len(username) >= 2:
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute('UPDATE users SET username = %s, updated_at = now() WHERE id = %s', (username, user['id']))
            conn.commit()
            cur.close()
            conn.close()
        except Exception as e:
            print(f'Update profile error: {e}')
            return jsonify({'error': 'Ошибка обновления профиля'}), 500
    
    return jsonify({'status': 'ok'})

@app.route('/api/payment/purchase', methods=['POST'])
@require_auth
def purchase_pearls():
    user = request.current_user
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Неверные данные"}), 400
    
    package_id = data.get("package_id")
    
    if not package_id or package_id not in PEARL_PACKAGES:
        return jsonify({"error": "Неверный пакет"}), 400
    
    package = PEARL_PACKAGES[package_id]
    total_pearls = package["pearls"] + package["bonus"]
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("""
            UPDATE users SET pearls = pearls + %s, updated_at = now()
            WHERE id = %s
            RETURNING pearls
        """, (total_pearls, user['id']))
        
        result = cur.fetchone()
        conn.commit()
        conn.close()
        
        if not result:
            return jsonify({"error": "Пользователь не найден"}), 404
        
        return jsonify({
            "status": "success",
            "package_id": package_id,
            "pearls_added": total_pearls,
            "new_balance": result["pearls"],
            "message": f"Вы получили {total_pearls} жемчужин!"
        })
        
    except Exception as e:
        print(f"Purchase error: {e}")
        return jsonify({"error": "Ошибка покупки"}), 500

@app.route('/api/news', methods=['GET'])
def get_news():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            SELECT id, title, content, news_type, is_new, created_at
            FROM news
            ORDER BY created_at DESC
            LIMIT 20
        ''')
        news = cur.fetchall()
        cur.close()
        conn.close()
        
        result = []
        for n in news:
            result.append({
                'id': n['id'],
                'title': n['title'],
                'content': n['content'],
                'type': n['news_type'],
                'isNew': n['is_new'],
                'date': n['created_at'].strftime('%Y-%m-%d') if n['created_at'] else ''
            })
        
        return jsonify({'news': result})
    except Exception as e:
        print(f'Get news error: {e}')
        return jsonify({'news': []})

@app.route('/api/admin/news', methods=['POST'])
@require_admin
def create_news():
    data = request.get_json(force=True)
    title = data.get('title', '').strip()
    content = data.get('content', '').strip()
    news_type = data.get('news_type', 'update')
    
    if not title or not content:
        return jsonify({'error': 'Заполните заголовок и содержание'}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO news (title, content, news_type)
            VALUES (%s, %s, %s)
            RETURNING id, title, content, news_type, is_new, created_at
        ''', (title, content, news_type))
        news = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({'news': dict(news)})
    except Exception as e:
        print(f'Create news error: {e}')
        return jsonify({'error': 'Ошибка создания новости'}), 500

@app.route('/api/admin/news/<int:news_id>', methods=['DELETE'])
@require_admin
def delete_news(news_id):
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('DELETE FROM news WHERE id = %s', (news_id,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'status': 'ok'})
    except Exception as e:
        print(f'Delete news error: {e}')
        return jsonify({'error': 'Ошибка удаления'}), 500

@app.route('/api/leaderboard', methods=['GET'])
def get_leaderboard():
    limit = min(int(request.args.get('limit', 50)), 100)
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            SELECT u.username, u.level, l.score, l.pvp_kills, l.pve_kills
            FROM leaderboard l
            JOIN users u ON l.user_id = u.id
            ORDER BY l.score DESC
            LIMIT %s
        ''', (limit,))
        leaders = cur.fetchall()
        cur.close()
        conn.close()
        
        result = []
        for i, l in enumerate(leaders):
            result.append({
                'rank': i + 1,
                'username': l['username'],
                'level': l['level'],
                'score': l['score'],
                'pvp_kills': l['pvp_kills'],
                'pve_kills': l['pve_kills']
            })
        
        return jsonify({'leaderboard': result})
    except Exception as e:
        print(f'Get leaderboard error: {e}')
        return jsonify({'leaderboard': []})

@app.route('/api/online', methods=['GET'])
def get_online_count():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            SELECT COUNT(*) as count FROM online_users
            WHERE last_seen > now() - interval '5 minutes'
        ''')
        result = cur.fetchone()
        count = result['count'] if result else 0
        cur.close()
        conn.close()
        return jsonify({'online': count})
    except Exception as e:
        print(f'Get online error: {e}')
        return jsonify({'online': 0})

@app.route('/api/online/heartbeat', methods=['POST'])
@require_auth
def heartbeat():
    user = request.current_user
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            INSERT INTO online_users (user_id, last_seen)
            VALUES (%s, now())
            ON CONFLICT (user_id) DO UPDATE SET last_seen = now()
        ''', (user['id'],))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f'Heartbeat error: {e}')
    return jsonify({'status': 'ok'})

@app.route('/api/guides', methods=['GET'])
def get_guides():
    guides = [
        {
            'id': 1,
            'title': 'Начало игры',
            'category': 'beginner',
            'icon': '🏝️',
            'content': '''## Добро пожаловать в Isleborn Online!

Вы начинаете игру на маленьком острове 5x5 метров. Ваша цель - выжить, развить свой остров и стать властелином океана!

### Первые шаги:
1. **Осмотритесь** - на вашем острове есть пальма и камень для добычи ресурсов
2. **Соберите ресурсы** - подойдите к объекту и нажмите E для сбора
3. **Постройте костёр** - это защитит вас ночью и позволит готовить еду
4. **Сделайте лодку** - соберите достаточно древесины и отправляйтесь исследовать океан

### Управление:
- WASD - движение
- E - взаимодействие
- I - инвентарь
- M - карта
- Tab - статистика'''
        },
        {
            'id': 2,
            'title': 'Система островов',
            'category': 'islands',
            'icon': '🌴',
            'content': '''## Система островов

Ваш остров - ваша крепость! Он растёт вместе с вами.

### Уровни острова:
- **Уровень 1**: 5x5 м - начальный остров
- **Уровень 2**: 10x10 м - разблокируется на 5 уровне персонажа
- **Уровень 3**: 25x25 м - разблокируется на 15 уровне
- **Уровень 4**: 50x50 м - разблокируется на 30 уровне
- **Уровень 5**: 100x100 м - разблокируется на 50 уровне
- **Максимум**: 250x250 м - для элитных игроков

### Постройки:
- Костёр - базовая защита
- Верстак - крафт инструментов
- Печь - готовка и плавка
- Верфь - строительство кораблей
- Склад - хранение ресурсов'''
        },
        {
            'id': 3,
            'title': 'Морские путешествия',
            'category': 'ships',
            'icon': '⛵',
            'content': '''## Морские путешествия

Океан полон опасностей и сокровищ!

### Типы кораблей:
- **Плот** - простой, медленный, но доступный
- **Лодка** - быстрее плота, вмещает больше груза
- **Шлюп** - маленький боевой корабль
- **Бригантина** - средний корабль для торговли
- **Галеон** - большой боевой корабль
- **Фрегат** - быстрый военный корабль

### Опасности:
- Монстры глубин - атакуют корабли
- Штормы - могут потопить слабые суда
- Пираты - игроки в PvP режиме
- Левиафаны - мировые боссы'''
        },
        {
            'id': 4,
            'title': 'PvP и PvE',
            'category': 'combat',
            'icon': '⚔️',
            'content': '''## Боевая система

### PvE (Против монстров):
- Монстры появляются в океане
- Глубоководные существа опаснее
- Убийство даёт опыт и ресурсы
- Мировые боссы появляются по расписанию

### PvP (Против игроков):
- Включите PvP режим командой /pvp
- Атакуйте корабли других игроков
- Захватывайте ресурсы
- За убийство получаете очки славы
- При смерти теряете часть ресурсов

### Советы:
- Не включайте PvP на слабом корабле
- Объединяйтесь в гильдии для защиты
- Используйте течения для побега'''
        },
        {
            'id': 5,
            'title': 'Крафт и ресурсы',
            'category': 'crafting',
            'icon': '🔨',
            'content': '''## Крафт и ресурсы

### Основные ресурсы:
- **Древесина** - из пальм, для построек и кораблей
- **Камень** - для инструментов и фундаментов
- **Железо** - редкий ресурс для оружия
- **Ткань** - для парусов и одежды
- **Рыба** - еда и приманка

### Рабочие станции:
1. **Костёр** - готовка еды
2. **Верстак** - базовые инструменты
3. **Наковальня** - металлические предметы
4. **Ткацкий станок** - паруса и одежда
5. **Верфь** - корабли

### Советы:
- Собирайте всё на начальном этапе
- Храните ресурсы в сундуках
- Изучайте рецепты через книги'''
        }
    ]
    return jsonify({'guides': guides})

@app.route('/api/admin/users', methods=['GET'])
@require_admin
def admin_get_users():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('''
            SELECT id, email, username, level, pearls, is_admin, created_at
            FROM users
            ORDER BY created_at DESC
            LIMIT 100
        ''')
        users = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify({'users': [dict(u) for u in users]})
    except Exception as e:
        print(f'Admin get users error: {e}')
        return jsonify({'users': []})

@app.route('/api/admin/user/<int:user_id>/toggle-admin', methods=['POST'])
@require_admin
def toggle_admin(user_id):
    if user_id == request.current_user['id']:
        return jsonify({'error': 'Нельзя изменить свой статус'}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute('UPDATE users SET is_admin = NOT is_admin WHERE id = %s', (user_id,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'status': 'ok'})
    except Exception as e:
        print(f'Toggle admin error: {e}')
        return jsonify({'error': 'Ошибка'}), 500

@app.route('/api/admin/stats', methods=['GET'])
@require_admin
def admin_stats():
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute('SELECT COUNT(*) as count FROM users')
        total_users = cur.fetchone()['count']
        
        cur.execute('SELECT COUNT(*) as count FROM online_users WHERE last_seen > now() - interval \'5 minutes\'')
        online_users = cur.fetchone()['count']
        
        cur.execute('SELECT COUNT(*) as count FROM islands')
        total_islands = cur.fetchone()['count']
        
        cur.close()
        conn.close()
        
        return jsonify({
            'total_users': total_users,
            'online_users': online_users,
            'total_islands': total_islands
        })
    except Exception as e:
        print(f'Admin stats error: {e}')
        return jsonify({'total_users': 0, 'online_users': 0, 'total_islands': 0})

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
