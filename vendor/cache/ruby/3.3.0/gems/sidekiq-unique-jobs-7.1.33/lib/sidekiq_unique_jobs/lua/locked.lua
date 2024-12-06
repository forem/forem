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
local job_id = ARGV[1]
-------- END lock arguments -----------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local debug_lua    = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = tostring(ARGV[5]) .. ".lua"
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
---------  END local functions ---------


--------  BEGIN locked.lua --------
if redis.call("HEXISTS", locked, job_id) == 1 then
  log_debug("Locked", digest, "job_id:", job_id)
  return 1
else
  log_debug("NOT Locked", digest, "job_id:", job_id)
  return -1
end
---------  END locked.lua ---------
