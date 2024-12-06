local function find_digest_in_queues(digest)
  local cursor = "0"
  local count  = 50
  local result = nil
  local found  = false

  repeat
    log_debug("searching all queues for a matching digest:", digest)
    local pagination  = redis.call("SCAN", cursor, "MATCH", "queue:*", "COUNT", count)
    local next_cursor = pagination[1]
    local queues      = pagination[2]

    for _, queue in ipairs(queues) do
      local per    = 50
      local total  = redis.call("LLEN", queue)
      local index  = 0

      log_debug("searching in:", queue,
                "for digest:", digest,
                "from:", index,
                "to:", total,
                "(per: " .. per .. ")",
                "cursor:", cursor)

      while (index < total) do
        local items = redis.call("LRANGE", queue, index, index + per -1)
        for _, item in pairs(items) do
          if string.find(item, digest) then
            log_debug("Found digest:", digest, "in queue:", queue)
            result = cjson.decode(item).queue
            found = true
            break
          end
        end
        index = index + per
      end
    end

    cursor = next_cursor
  until found == true or cursor == "0"

  return result
end
