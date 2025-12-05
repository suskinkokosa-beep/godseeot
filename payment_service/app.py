#!/usr/bin/env python3
"""
Payment Service для Isleborn Online
Обрабатывает аутентификацию и покупки премиум-валюты Pearls
"""

from flask import Flask, request, jsonify, abort
from flask_cors import CORS
import os
import json
import hashlib
import secrets
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
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

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "payment_service"})

@app.route('/api/auth/register', methods=['POST'])
def register():
    """Регистрация нового пользователя"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "Неверные данные"}), 400
    
    email = data.get("email", "").strip().lower()
    password = data.get("password", "")
    username = data.get("username", "").strip()
    
    if not email or not password or not username:
        return jsonify({"error": "Заполните все поля"}), 400
    
    if len(password) < 6:
        return jsonify({"error": "Пароль должен быть не менее 6 символов"}), 400
    
    if len(username) < 2:
        return jsonify({"error": "Имя пользователя должно быть не менее 2 символов"}), 400
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("SELECT id FROM users WHERE email = %s", (email,))
        if cur.fetchone():
            conn.close()
            return jsonify({"error": "Пользователь с таким email уже существует"}), 400
        
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
        return jsonify({"error": "Ошибка регистрации"}), 500

@app.route('/api/auth/login', methods=['POST'])
def login():
    """Вход пользователя"""
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
        
        password_hash = hash_password(password)
        
        cur.execute("""
            SELECT id, username, email, pearls, level, playtime, islands, achievements
            FROM users WHERE email = %s AND password_hash = %s
        """, (email, password_hash))
        
        user = cur.fetchone()
        conn.close()
        
        if not user:
            return jsonify({"error": "Неверный email или пароль"}), 401
        
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
        return jsonify({"error": "Ошибка входа"}), 500

@app.route('/api/auth/verify', methods=['POST'])
def verify_token():
    """Проверка токена и получение данных пользователя"""
    data = request.get_json()
    token = data.get("token") if data else None
    
    if not token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:]
    
    if not token or token not in active_tokens:
        return jsonify({"error": "Недействительный токен"}), 401
    
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
            return jsonify({"error": "Пользователь не найден"}), 401
        
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
        return jsonify({"error": "Ошибка проверки"}), 500

@app.route('/api/auth/logout', methods=['POST'])
def logout():
    """Выход пользователя"""
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
    """Получить список доступных пакетов Pearls"""
    return jsonify({"packages": PEARL_PACKAGES})

@app.route('/api/user/pearls', methods=['GET'])
def get_user_pearls():
    """Получить баланс Pearls пользователя"""
    auth_header = request.headers.get("Authorization", "")
    token = auth_header[7:] if auth_header.startswith("Bearer ") else None
    
    if not token or token not in active_tokens:
        return jsonify({"error": "Требуется авторизация"}), 401
    
    user_id = active_tokens[token]
    
    try:
        conn = get_db()
        cur = conn.cursor()
        
        cur.execute("SELECT pearls FROM users WHERE id = %s", (user_id,))
        user = cur.fetchone()
        conn.close()
        
        if not user:
            return jsonify({"error": "Пользователь не найден"}), 404
        
        return jsonify({
            "user_id": user_id,
            "pearls": user["pearls"]
        })
        
    except Exception as e:
        print(f"Get pearls error: {e}")
        return jsonify({"error": "Ошибка получения баланса"}), 500

@app.route('/api/payment/purchase', methods=['POST'])
def purchase_pearls():
    """Покупка пакета Pearls"""
    auth_header = request.headers.get("Authorization", "")
    token = auth_header[7:] if auth_header.startswith("Bearer ") else None
    
    if not token or token not in active_tokens:
        return jsonify({"error": "Требуется авторизация"}), 401
    
    user_id = active_tokens[token]
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
            UPDATE users SET pearls = pearls + %s, updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING pearls
        """, (total_pearls, user_id))
        
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

@app.route('/api/payment/confirm', methods=['POST'])
def confirm_payment():
    """Подтверждение платежа (для webhook от платежного шлюза)"""
    data = request.get_json()
    
    payment_id = data.get("payment_id")
    user_id = data.get("user_id")
    package_id = data.get("package_id")
    
    if not all([payment_id, user_id, package_id]):
        return jsonify({"error": "Отсутствуют обязательные поля"}), 400
    
    if package_id not in PEARL_PACKAGES:
        return jsonify({"error": "Неверный пакет"}), 400
    
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
            return jsonify({"error": "Пользователь не найден"}), 404
        
        return jsonify({
            "status": "success",
            "user_id": user_id,
            "pearls_added": total_pearls,
            "new_balance": result["pearls"]
        })
        
    except Exception as e:
        print(f"Confirm error: {e}")
        return jsonify({"error": "Ошибка подтверждения"}), 500

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8081))
    app.run(host='0.0.0.0', port=port, debug=True)
