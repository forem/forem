local function toversion(version)
  local _, _, maj, min, pat = string.find(version, "(%d+)%.(%d+)%.(%d+)")

  return {
    ["version"] = version,
    ["major"]   = tonumber(maj),
    ["minor"]   = tonumber(min),
    ["patch"]   = tonumber(pat)
  }
end

local function toboolean(val)
  val = tostring(val)
  return val == "1" or val == "true"
end

local function log_debug( ... )
  if debug_lua ~= true then return end

  local result = ""
  for _,v in ipairs(arg) do
    result = result .. " " .. tostring(v)
  end
  redis.log(redis.LOG_DEBUG, script_name .. " -" ..  result)
end

local function log(message, prev_jid)
  if not max_history or max_history == 0 then return end
  local entry = cjson.encode({digest = digest, job_id = job_id, script = script_name, message = message, time = current_time, prev_jid = prev_jid })

  log_debug("ZADD", changelog, current_time, entry);
  redis.call("ZADD", changelog, current_time, entry);
  local total_entries = redis.call("ZCARD", changelog)
  local removed_entries = redis.call("ZREMRANGEBYRANK", changelog, 0, -1 * max_history)
  if removed_entries > 0 then
    log_debug("Removing", removed_entries , "entries from changelog (total entries", total_entries, "exceeds max_history:", max_history ..")");
  end
  log_debug("PUBLISH", changelog, entry);
  redis.call("PUBLISH", changelog, entry);
end
