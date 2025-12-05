# Payment Service - Isleborn Online

Сервис для обработки покупок премиум-валюты Pearls.

## Запуск

```bash
# Установка зависимостей
pip install -r requirements.txt

# Запуск сервера
python app.py
```

Или через Docker:

```bash
docker build -t payment_service .
docker run -p 8081:8081 payment_service
```

## API Endpoints

- `GET /health` - Проверка здоровья сервиса
- `GET /api/packages` - Список доступных пакетов
- `POST /api/payment/purchase` - Создание заказа
- `POST /api/payment/confirm` - Подтверждение платежа (webhook)
- `GET /api/user/pearls` - Получить баланс Pearls

## Интеграция с платежным шлюзом

В production нужно интегрировать с:
- YooKassa (для России)
- Stripe (для международных платежей)
- PayPal (опционально)

## TODO

- [ ] Интеграция с Nakama для начисления Pearls
- [ ] Интеграция с реальным платежным шлюзом
- [ ] Валидация платежей
- [ ] Логирование транзакций
- [ ] Защита от дублирования платежей

