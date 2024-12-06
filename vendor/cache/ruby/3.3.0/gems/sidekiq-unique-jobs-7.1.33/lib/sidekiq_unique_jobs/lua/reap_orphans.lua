redis.replicate_commands()

-------- BEGIN keys ---------
local digests_set          = KEYS[1]
local expiring_digests_set = KEYS[2]
local schedule_set         = KEYS[3]
local retry_set            = KEYS[4]
--------  END keys  ---------

-------- BEGIN argv ---------
local reaper_count = tonumber(ARGV[1])
local threshold    = tonumber(ARGV[2])
--------  END argv  ---------

--------  BEGIN injected arguments --------
local current_time = tonumber(ARGV[3])
local debug_lua    = ARGV[4] == "true"
local max_history  = tonumber(ARGV[5])
local script_name  = ARGV[6] .. ".lua"
local redisversion = ARGV[7]
---------  END injected arguments ---------


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
<%= include_partial "shared/_find_digest_in_queues.lua" %>
<%= include_partial "shared/_find_digest_in_sorted_set.lua" %>
<%= include_partial "shared/_find_digest_in_process_set.lua" %>
----------  END local functions ----------


--------  BEGIN delete_orphaned.lua --------
log_debug("BEGIN")
local found     = false
local per       = 50
local total     = redis.call("ZCARD", digests_set)
local index     = 0
local del_count = 0
local redis_ver = toversion(redisversion)
local del_cmd   = "DEL"

if tonumber(redis_ver["major"]) >= 4 then del_cmd = "UNLINK"; end

repeat
  log_debug("Interating through:", digests_set, "for orphaned locks")
  local digests  = redis.call("ZREVRANGE", digests_set, index, index + per -1)

  for _, digest in pairs(digests) do
    log_debug("Searching for digest:", digest, "in", schedule_set)
    found = find_digest_in_sorted_set(schedule_set, digest)

    if found ~= true then
      log_debug("Searching for digest:", digest, "in", retry_set)
      found = find_digest_in_sorted_set(retry_set, digest)
    end

    if found ~= true then
      log_debug("Searching for digest:", digest, "in all queues")
      local queue = find_digest_in_queues(digest)

      if queue then
        log_debug("found digest:", digest, "in queue:", queue)
        found = true
      end
    end

    -- TODO: Add check for jobs checked out by process
    if found ~= true then
      log_debug("Searching for digest:", digest, "in process sets")
      found = find_digest_in_process_set(digest, threshold)
    end

    if found ~= true then
      local queued     = digest .. ":QUEUED"
      local primed     = digest .. ":PRIMED"
      local locked     = digest .. ":LOCKED"
      local info       = digest .. ":INFO"
      local run_digest = digest .. ":RUN"
      local run_queued = digest .. ":RUN:QUEUED"
      local run_primed = digest .. ":RUN:PRIMED"
      local run_locked = digest .. ":RUN:LOCKED"
      local run_info   = digest .. ":RUN:INFO"

      redis.call(del_cmd, digest, queued, primed, locked, info, run_digest, run_queued, run_primed, run_locked, run_info)

      redis.call("ZREM", digests_set, digest)
      del_count = del_count + 1
    end
  end

  index = index + per
until index >= total or del_count >= reaper_count

if del_count < reaper_count then
  index = 0
  total = redis.call("ZCOUNT", expiring_digests_set, 0, current_time)
  repeat
    local digests = redis.call("ZRANGEBYSCORE", expiring_digests_set, 0, current_time, "LIMIT", index, index + per -1)

    for _, digest in pairs(digests) do
      local queued     = digest .. ":QUEUED"
      local primed     = digest .. ":PRIMED"
      local locked     = digest .. ":LOCKED"
      local info       = digest .. ":INFO"
      local run_digest = digest .. ":RUN"
      local run_queued = digest .. ":RUN:QUEUED"
      local run_primed = digest .. ":RUN:PRIMED"
      local run_locked = digest .. ":RUN:LOCKED"
      local run_info   = digest .. ":RUN:INFO"

      redis.call(del_cmd, digest, queued, primed, locked, info, run_digest, run_queued, run_primed, run_locked, run_info)

      redis.call("ZREM", expiring_digests_set, digest)
      del_count = del_count + 1
    end

    index = index + per
  until index >= total or del_count >= reaper_count
end

log_debug("END")
return del_count
