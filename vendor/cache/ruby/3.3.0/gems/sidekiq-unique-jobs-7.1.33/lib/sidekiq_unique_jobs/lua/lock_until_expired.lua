-------- BEGIN keys ---------
local digest           = KEYS[1]
local queued           = KEYS[2]
local primed           = KEYS[3]
local locked           = KEYS[4]
local info             = KEYS[5]
local changelog        = KEYS[6]
local digests          = KEYS[7]
local expiring_digests = KEYS[8]
-------- END keys ---------


-------- BEGIN lock arguments ---------
local job_id       = ARGV[1]
local pttl         = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local limit        = tonumber(ARGV[4])
-------- END lock arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua    = ARGV[6] == "true"
local max_history  = tonumber(ARGV[7])
local script_name  = tostring(ARGV[8]) .. ".lua"
local redisversion = ARGV[9]
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


---------  BEGIN lock.lua ---------
log_debug("BEGIN lock digest:", digest, "job_id:", job_id)

if redis.call("HEXISTS", locked, job_id) == 1 then
  log_debug(locked, "already locked with job_id:", job_id)
  log("Duplicate")

  log_debug("LREM", queued, -1, job_id)
  redis.call("LREM", queued, -1, job_id)

  log_debug("LREM", primed, 1, job_id)
  redis.call("LREM", primed, 1, job_id)

  return job_id
end

local locked_count   = redis.call("HLEN", locked)
local within_limit   = limit > locked_count
local limit_exceeded = not within_limit

if limit_exceeded then
  log_debug("Limit exceeded:", digest, "(",  locked_count, "of", limit, ")")
  log("Limited")
  return nil
end

log_debug("ZADD", expiring_digests, current_time + pttl, digest)
redis.call("ZADD", expiring_digests, current_time + pttl, digest)

log_debug("HSET", locked, job_id, current_time)
redis.call("HSET", locked, job_id, current_time)

log_debug("LREM", queued, -1, job_id)
redis.call("LREM", queued, -1, job_id)

log_debug("LREM", primed, 1, job_id)
redis.call("LREM", primed, 1, job_id)

-- The Sidekiq client sets pttl
log_debug("PEXPIRE", digest, pttl)
redis.call("PEXPIRE", digest, pttl)

log_debug("PEXPIRE", locked, pttl)
redis.call("PEXPIRE", locked, pttl)

log_debug("PEXPIRE", info, pttl)
redis.call("PEXPIRE", info, pttl)

log_debug("PEXPIRE", queued, 1000)
redis.call("PEXPIRE", queued, 1000)

log_debug("PEXPIRE", primed, 1000)
redis.call("PEXPIRE", primed, 1000)

log("Locked")
log_debug("END lock digest:", digest, "job_id:", job_id)
return job_id
----------  END lock.lua  ----------
