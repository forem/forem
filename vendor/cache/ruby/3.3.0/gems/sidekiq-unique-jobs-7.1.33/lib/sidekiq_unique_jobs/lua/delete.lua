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
local job_id       = ARGV[1]
local pttl         = tonumber(ARGV[2])
local lock_type    = ARGV[3]
local limit        = tonumber(ARGV[4])
-------- END lock arguments -----------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua    = tostring(ARGV[6]) == "true"
local max_history  = tonumber(ARGV[7])
local script_name  = tostring(ARGV[8]) .. ".lua"
local redisversion = tostring(ARGV[9])
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


--------  BEGIN delete.lua --------
log_debug("BEGIN delete", digest)

local redis_version  = toversion(redisversion)
local count          = 0
local del_cmd        = "DEL"

log_debug("ZREM", digests, digest)
count = count + redis.call("ZREM", digests, digest)

if redis_version["major"] >= 4 then del_cmd = "UNLINK"; end

log_debug(del_cmd, digest, queued, primed, locked, info)
count = count + redis.call(del_cmd, digest, queued, primed, locked, info)


log("Deleted (" .. count .. ") keys")
log_debug("END delete (" .. count .. ") keys for:", digest)

return count
--------  END delete.lua --------
