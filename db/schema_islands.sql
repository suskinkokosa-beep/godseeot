-- islands schema for Postgres
CREATE TABLE IF NOT EXISTS islands (
  owner TEXT PRIMARY KEY,
  owner_name TEXT,
  level INTEGER DEFAULT 1,
  json_state JSONB NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Index on updated_at for querying active islands
CREATE INDEX IF NOT EXISTS idx_islands_updated_at ON islands (updated_at DESC);
