-- token_bucket.lua
-- KEYS[1] = key (per-ip)
-- ARGV[1] = max_tokens (burst)
-- ARGV[2] = refill_rate (tokens per second)
local key = KEYS[1]
local max_tokens = tonumber(ARGV[1])
local rate = tonumber(ARGV[2])
local now = redis.call('TIME')
local ts = tonumber(now[1])
-- Use a simple fixed window with counter and expiry of 2 seconds
local count = redis.call('INCR', key)
if count == 1 then
  redis.call('EXPIRE', key, 2)
end
if count > (max_tokens + rate) then
  return {0, max_tokens + rate - (count - 1)}
end
return {1, max_tokens + rate - (count - 1)}
