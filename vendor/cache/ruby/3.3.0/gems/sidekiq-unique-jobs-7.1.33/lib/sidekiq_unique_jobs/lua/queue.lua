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
local job_id    = ARGV[1]      -- The job_id that was previously primed
local pttl      = tonumber(ARGV[2])
local lock_type = ARGV[3]
local limit     = tonumber(ARGV[4])
-------- END lock arguments -----------


--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua    = ARGV[6] == "true"
local max_history  = tonumber(ARGV[7])
local script_name  = tostring(ARGV[8]) .. ".lua"
---------  END injected arguments ---------


--------  BEGIN Variables --------
local queued_count = redis.call("LLEN", queued)
local locked_count = redis.call("HLEN", locked)
local within_limit = limit > locked_count
local limit_exceeded = not within_limit
--------   END Variables  --------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


--------  BEGIN queue.lua --------
log_debug("BEGIN queue with key:", digest, "for job:", job_id)

if redis.call("HEXISTS", locked, job_id) == 1 then
  log_debug("HEXISTS", locked, job_id, "== 1")
  log("Duplicate")
  return job_id
end

local prev_jid = redis.call("GET", digest)
log_debug("job_id:", job_id, "prev_jid:", prev_jid)
if not prev_jid or prev_jid == false then
  log_debug("SET", digest, job_id)
  redis.call("SET", digest, job_id)
elseif prev_jid == job_id then
  log_debug(digest, "already queued with job_id:", job_id)
  log("Duplicate")
  return job_id
else
  -- TODO: Consider constraining the total count of both locked and queued?
  if within_limit and queued_count < limit then
    log_debug("Within limit:", digest, "(",  locked_count, "of", limit, ")", "queued (", queued_count, "of", limit, ")")
    log_debug("SET", digest, job_id, "(was", prev_jid, ")")
    redis.call("SET", digest, job_id)
  else
    log_debug("Limit exceeded:", digest, "(",  locked_count, "of", limit, ")")
    log("Limit exceeded", prev_jid)
    return prev_jid
  end
end

log_debug("LPUSH", queued, job_id)
redis.call("LPUSH", queued, job_id)

-- The Sidekiq client should only set pttl for until_expired
-- The Sidekiq server should set pttl for all other jobs
if pttl and pttl > 0 then
  log_debug("PEXPIRE", digest, pttl)
  redis.call("PEXPIRE", digest, pttl)
  log_debug("PEXPIRE", queued, pttl)
  redis.call("PEXPIRE", queued, pttl)
end

log("Queued")
log_debug("END queue with key:", digest, "for job:", job_id)
return job_id
--------  END queue.lua --------
