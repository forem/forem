-------- BEGIN keys ---------
local digest    = KEYS[1]
local queued    = KEYS[2]
local primed    = KEYS[3]
local locked    = KEYS[4]
local info      = KEYS[5]
local changelog = KEYS[6]
local digests   = KEYS[7]
-------- END keys ---------


-------- BEGIN lock arguments ---------
local job_id    = ARGV[1]
local pttl      = tonumber(ARGV[2])
local lock_type = ARGV[3]
local limit     = tonumber(ARGV[4])
-------- END lock arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua    = ARGV[6] == "true"
local max_history  = tonumber(ARGV[7])
local script_name  = tostring(ARGV[8]) .. ".lua"
local redisversion = ARGV[9]
---------  END injected arguments ---------


--------  BEGIN Variables --------
local queued_count = redis.call("LLEN", queued)
local primed_count = redis.call("LLEN", primed)
local locked_count = redis.call("HLEN", locked)
---------  END Variables ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


---------  Begin unlock.lua ---------
log_debug("BEGIN unlock digest:", digest, "(job_id: " .. job_id ..")")

log_debug("HEXISTS", locked, job_id)
if redis.call("HEXISTS", locked, job_id) == 0 then
  -- TODO: Improve orphaned lock detection
  if queued_count == 0 and primed_count == 0 and locked_count == 0 then
    log_debug("Orphaned lock")
  else
    local result = ""
    for i,v in ipairs(redis.call("HKEYS", locked)) do
      result = result .. v .. ","
    end
    result = locked .. " (" .. result .. ")"
    log("Yielding to: " .. result)
    log_debug("Yielding to", result, locked, "by job", job_id)
    return nil
  end
end

-- Just in case something went wrong
log_debug("LREM", queued, -1, job_id)
redis.call("LREM", queued, -1, job_id)

log_debug("LREM", primed, -1, job_id)
redis.call("LREM", primed, -1, job_id)

local redis_version = toversion(redisversion)
local del_cmd       = "DEL"

if tonumber(redis_version["major"]) >= 4 then del_cmd =  "UNLINK"; end

if lock_type ~= "until_expired" then
  log_debug(del_cmd, digest, info)
  redis.call(del_cmd, digest, info)

  log_debug("HDEL", locked, job_id)
  redis.call("HDEL", locked, job_id)
end

local locked_count = redis.call("HLEN", locked)

if locked_count and locked_count < 1 then
  log_debug(del_cmd, locked)
  redis.call(del_cmd, locked)
end

if redis.call("LLEN", primed) == 0 then
  log_debug(del_cmd, primed)
  redis.call(del_cmd, primed)
end

if limit and limit <= 1 and locked_count and locked_count <= 1 then
  log_debug("ZREM", digests, digest)
  redis.call("ZREM", digests, digest)
end

log_debug("LPUSH", queued, "1")
redis.call("LPUSH", queued, "1")

log_debug("PEXPIRE", queued, 5000)
redis.call("PEXPIRE", queued, 5000)

log("Unlocked")
log_debug("END unlock digest:", digest, "(job_id: " .. job_id ..")")
return job_id
---------  END unlock.lua ---------
