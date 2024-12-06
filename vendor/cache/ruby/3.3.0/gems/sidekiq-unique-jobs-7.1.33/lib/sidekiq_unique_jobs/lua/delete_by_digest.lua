-------- BEGIN keys ---------
local digest     = KEYS[1]
local queued     = KEYS[2]
local primed     = KEYS[3]
local locked     = KEYS[4]
local run_digest = KEYS[5]
local run_queued = KEYS[6]
local run_primed = KEYS[7]
local run_locked = KEYS[8]
local digests    = KEYS[9]
--------  END keys  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[1])
local debug_lua    = ARGV[2] == "true"
local max_history  = tonumber(ARGV[3])
local script_name  = tostring(ARGV[4]) .. ".lua"
local redisversion = tostring(ARGV[5])
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------

--------  BEGIN delete_by_digest.lua --------
local counter       = 0
local redis_version = toversion(redisversion)
local del_cmd       = "DEL"

log_debug("BEGIN delete_by_digest:", digest)

if redis_version["major"] >= 4 then del_cmd = "UNLINK"; end

log_debug(del_cmd, digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)
counter = redis.call(del_cmd, digest, queued, primed, locked, run_digest, run_queued, run_primed, run_locked)

log_debug("ZREM", digests, digest)
redis.call("ZREM", digests, digest)

log_debug("END delete_by_digest:", digest, "(deleted " ..  counter .. " keys)")
return counter
--------   END delete_by_digest.lua  --------
