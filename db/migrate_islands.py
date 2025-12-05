#!/usr/bin/env python3
"""migrate_islands.py
Reads JSON files from godot_server/islands/ and upserts them into Postgres table `islands`.

Usage:
  pip install psycopg2-binary
  export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/isleborn
  python migrate_islands.py --source ./godot_server/islands

This script is idempotent and uses ON CONFLICT DO UPDATE.
"""
import os, json, argparse, psycopg2, glob
from psycopg2.extras import Json

def load_files(source):
    files = glob.glob(os.path.join(source, 'island_*.json'))
    out = []
    for f in files:
        with open(f, 'r', encoding='utf-8') as fh:
            try:
                data = json.load(fh)
                owner = os.path.splitext(os.path.basename(f))[0].replace('island_', '')
                out.append((owner, data))
            except Exception as e:
                print('Failed to parse', f, e)
    return out

def migrate(db_url, source):
    rows = load_files(source)
    if not rows:
        print('No island files found in', source)
        return
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    for owner, data in rows:
        owner_name = data.get('owner_name') or data.get('owner') or owner
        level = data.get('level', 1)
        cur.execute("""
            INSERT INTO islands (owner, owner_name, level, json_state, updated_at)
            VALUES (%s, %s, %s, %s, now())
            ON CONFLICT (owner) DO UPDATE SET
              owner_name = EXCLUDED.owner_name,
              level = EXCLUDED.level,
              json_state = EXCLUDED.json_state,
              updated_at = now();
        """, (owner, owner_name, level, Json(data)))
        print('Upserted island', owner)
    conn.commit()
    cur.close()
    conn.close()

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--source', default='./godot_server/islands', help='source folder of island JSON (default ./godot_server/islands)')
    p.add_argument('--db', default=os.environ.get('DATABASE_URL'), help='Postgres DATABASE_URL or env DATABASE_URL')
    args = p.parse_args()
    if not args.db:
        print('DATABASE_URL not provided. Set env or use --db.')
    else:
        migrate(args.db, args.source)
