redis.replicate_commands()
-------- BEGIN keys ---------
local live_version = KEYS[1]
local dead_version = KEYS[2]
-------- END keys ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[5])
local debug_lua    = ARGV[6] == "true"
local max_history  = tonumber(ARGV[7])
local script_name  = tostring(ARGV[8]) .. ".lua"
local redisversion = ARGV[9]
---------  END injected arguments ---------

--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
<%= include_partial "shared/_upgrades.lua" %>
----------  END local functions ----------


local new_version   = redis.call("GET", live_version)
local old_version   = redis.call("GET", dead_version)
local redis_version = toversion(redisversion)
local upgraded      = 0
local del_cmd       = "DEL"

if redis_version["major"] >= 4 then del_cmd = "UNLINK"; end
--------  BEGIN delete.lua --------

log_debug("BEGIN upgrading from: ", old_version, "to:", new_version)

-- 1. Loop through all uniquejobs:jajshdahdas:GRABBED
local cursor = "0"
local per   = 50
repeat
  local pagination   = redis.call("SCAN", cursor, "MATCH", "*:GRABBED", "COUNT", per)
  local next_cursor  = pagination[1]
  local grabbed_keys = pagination[2]

  for _, grabbed in ipairs(grabbed_keys) do
    local locked_key = grabbed.gsub(":GRABBED", ":LOCKED")
    local locks      = redis.call("HGETALL", grabbed)

    if #locks == 0 then
      log_debug("No entries in:", grabbed)
    else
      log_debug("HMSET", locked_key, unpack(locks))
      redis.call("HMSET", locked_key, unpack(locks))
    end

    log_debug("DEL", grabbed)
    redis.call("DEL", grabbed)

    upgraded = upgraded + 1
  end

  cursor = next_cursor
  if cursor == "0" then
    log_debug("Looped through all grabbed keys, stopping iteration")
  end
until cursor == "0"



log_debug("END upgrading from: ", old_version, "to:", new_version)

return
--------  END delete.lua --------
