Islands persistence (MVP)
------------------------
- Islands are stored per-player as JSON files in godot_server/islands/island_<sub>.json
- This is a temporary persistence layer for MVP. Production plan:
  - Move to PostgreSQL table `islands` with columns: owner, owner_name, level, json_state, updated_at
  - Use Redis for caching hot islands (recently active), write-through policy
  - Implement migration script to import JSON files into Postgres
  - Add backup/restore logic and versioning for island JSON format
