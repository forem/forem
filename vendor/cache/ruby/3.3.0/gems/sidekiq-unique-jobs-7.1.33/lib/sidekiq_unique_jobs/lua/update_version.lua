-------- BEGIN keys ---------
local live_key = KEYS[1]
local dead_key = KEYS[2]
-------- END keys ---------

-------- BEGIN lock arguments ---------
local version  = ARGV[1]
-------- END lock arguments -----------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local debug_lua    = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = tostring(ARGV[5]) .. ".lua"
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------


--------  BEGIN set_version.lua --------
log_debug("BEGIN setting version:", version)

local updated     = false
local old_version = redis.call("GETSET", live_key, version)

if not old_version then
  log_debug("No previous version found")
  updated = true
elseif old_version ~= version then
  log_debug("Old version:", old_version, "differs from:", version)
  redis.call("SET", dead_key, old_version)
  updated = true
end

return updated
--------  END delete.lua --------


