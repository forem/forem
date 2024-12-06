-------- BEGIN keys ---------
local digest = KEYS[1]
--------  END keys  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[2])
local debug_lua    = ARGV[3] == "true"
local max_history  = tonumber(ARGV[4])
local script_name  = tostring(ARGV[5]) .. ".lua"
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
<%= include_partial "shared/_find_digest_in_queues.lua" %>
----------  END local functions ----------


--------  BEGIN delete_orphaned.lua --------
log_debug("BEGIN")
local result = find_digest_in_queues(digest)
log_debug("END")
if result and result ~= nil then
  return result
end
--------   END delete_orphaned.lua  --------
