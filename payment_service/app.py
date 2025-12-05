#!/usr/bin/env python3
"""
Payment Service для Isleborn Online
Обрабатывает покупки премиум-валюты Pearls за реальные деньги
"""

from flask import Flask, request, jsonify, abort
from flask_cors import CORS
import os
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Разрешаем CORS для веб-интерфейса

# Конфигурация
NAKAMA_BASE_URL = os.getenv("NAKAMA_BASE_URL", "http://localhost:7350")
PAYMENT_SECRET_KEY = os.getenv("PAYMENT_SECRET_KEY", "your_secret_key_here")

# Пакеты Pearls
PEARL_PACKAGES = {
    "pearls_100": {"pearls": 100, "price_rub": 99, "bonus": 0},
    "pearls_500": {"pearls": 500, "price_rub": 399, "bonus": 50},
    "pearls_1000": {"pearls": 1000, "price_rub": 699, "bonus": 150},
    "pearls_2500": {"pearls": 2500, "price_rub": 1499, "bonus": 500},
    "pearls_5000": {"pearls": 5000, "price_rub": 2499, "bonus": 1500}
}

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "payment_service"})

@app.route('/api/packages', methods=['GET'])
def get_packages():
    """Получить список доступных пакетов Pearls"""
    return jsonify({"packages": PEARL_PACKAGES})

@app.route('/api/payment/purchase', methods=['POST'])
def purchase_pearls():
    """
    Создать заказ на покупку Pearls
    В реальной игре здесь будет интеграция с платежным шлюзом (YooKassa, Stripe и т.д.)
    """
    data = request.get_json()
    
    if not data:
        abort(400, "Invalid request data")
    
    package_id = data.get("package_id")
    user_id = data.get("user_id")
    
    if not package_id or not user_id:
        abort(400, "Missing package_id or user_id")
    
    if package_id not in PEARL_PACKAGES:
        abort(400, "Invalid package_id")
    
    package = PEARL_PACKAGES[package_id]
    total_pearls = package["pearls"] + package["bonus"]
    
    # В реальной игре здесь:
    # 1. Создание платежа в платежном шлюзе
    # 2. Возврат URL для оплаты
    # 3. Webhook для подтверждения оплаты
    
    # Заглушка для демо
    return jsonify({
        "status": "success",
        "payment_id": f"payment_{datetime.now().timestamp()}",
        "package_id": package_id,
        "pearls": total_pearls,
        "price": package["price_rub"],
        "payment_url": f"http://localhost:8080/payment/demo?user_id={user_id}&package_id={package_id}",
        "message": "В демо режиме платеж считается успешным"
    })

@app.route('/api/payment/confirm', methods=['POST'])
def confirm_payment():
    """
    Подтверждение платежа (вызывается платежным шлюзом через webhook)
    """
    data = request.get_json()
    
    payment_id = data.get("payment_id")
    user_id = data.get("user_id")
    package_id = data.get("package_id")
    
    if not all([payment_id, user_id, package_id]):
        abort(400, "Missing required fields")
    
    if package_id not in PEARL_PACKAGES:
        abort(400, "Invalid package_id")
    
    package = PEARL_PACKAGES[package_id]
    total_pearls = package["pearls"] + package["bonus"]
    
    # Начисляем Pearls через Nakama Storage или API
    # TODO: Реализовать начисление через Nakama
    
    # Заглушка
    success = add_pearls_to_user(user_id, total_pearls)
    
    if success:
        return jsonify({
            "status": "success",
            "user_id": user_id,
            "pearls_added": total_pearls
        })
    else:
        abort(500, "Failed to add pearls")

def add_pearls_to_user(user_id: str, pearls: int) -> bool:
    """
    Добавить Pearls пользователю через Nakama
    В реальной игре использовать Nakama Storage или RPC
    """
    # TODO: Интеграция с Nakama
    # Использовать Nakama Storage для хранения баланса
    # Или Nakama RPC для начисления
    print(f"Adding {pearls} pearls to user {user_id}")
    return True

@app.route('/api/user/pearls', methods=['GET'])
def get_user_pearls():
    """Получить баланс Pearls пользователя"""
    user_id = request.args.get("user_id")
    
    if not user_id:
        abort(400, "Missing user_id")
    
    # TODO: Получить баланс из Nakama Storage
    # Заглушка
    return jsonify({
        "user_id": user_id,
        "pearls": 0
    })

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8081))
    app.run(host='0.0.0.0', port=port, debug=True)

