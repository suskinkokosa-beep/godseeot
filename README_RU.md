Isleborn Server — улучшенная сборка (MVP -> production-ready steps)

Что внутри:
- Gateway (Go): JWKS validation, Nakama RPC fallback, rate limiting, WS proxy.
- Nakama runtime: validate_session.lua (improved template + guidance).
- Godot headless project (server.gd) + placeholder & Dockerfile.
- Godot client demo (player.gd).
- Docker Compose for local stack (Postgres, Redis, Nakama, Gateway, World).
- CI template for Godot headless export (.github workflow).
- Скрипты: сборка/запуск/проверка/тесты (в scripts/).
- Подробная инструкция INSTRUCTION_RU.md (curl, websocat examples, ожидаемые логи).

Следующие шаги (рекомендации):
1) Настроить JWKS у провайдера или реализовать проверку подписи в Nakama runtime (рекомендуется — JWKS + Gateway).
2) Настроить TLS и секреты (Vault/Env).
3) Добавить Redis-backed rate limiter для Gateway при горизонтальном масштабировании.
4) Подключить мониторинг (Prometheus/Grafana) — могу положить пример в следующую версию.


Добавлено: мониторинг (Prometheus + Grafana) и Redis-backed rate limiter для Gateway.
