local function find_digest_in_process_set(digest, threshold)
  local process_cursor = 0
  local job_cursor     = 0
  local pattern        = "*" .. digest .. "*"
  local found          = false

  log_debug("Searching in process list",
            "for digest:", digest,
            "cursor:", process_cursor)

  repeat
    local process_paginator   = redis.call("SSCAN", "processes", process_cursor, "MATCH", "*")
    local next_process_cursor = process_paginator[1]
    local processes           = process_paginator[2]
    log_debug("Found number of processes:", #processes, "next cursor:", next_process_cursor)

    for _, process in ipairs(processes) do
      local workers_key = process .. ":work"
      log_debug("searching in process set:", process,
                "for digest:", digest,
                "cursor:", process_cursor)

      local jobs = redis.call("HGETALL", workers_key)

      if #jobs == 0 then
        log_debug("No entries in:", workers_key)
      else
        for i = 1, #jobs, 2 do
          local jobstr = jobs[i +1]
          if string.find(string.gsub(jobstr, ':RUN', ''), string.gsub(digest, ':RUN', '')) then
            log_debug("Found digest", digest, "in:", workers_key)
            found = true
            break
          end

          local job = cjson.decode(jobstr)
          if job.payload.created_at > threshold then
            found = true
            break
          end
        end
      end

      if found == true then
        break
      end
    end

    process_cursor = next_process_cursor
  until found == true or process_cursor == "0"

  return found
end
