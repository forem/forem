local function find_digest_in_sorted_set(name, digest)
  local cursor  = 0
  local count   = 5
  local pattern = "*" .. digest .. "*"
  local found   = false

  log_debug("searching in:", name,
            "for digest:", digest,
            "cursor:", cursor)
  repeat
    local pagination  = redis.call("ZSCAN", name, cursor, "MATCH", pattern, "COUNT", count)
    local next_cursor = pagination[1]
    local items       = pagination[2]

    if #items > 0 then
      log_debug("Found digest", digest, "in zset:", name)
      found = true
    end

    cursor = next_cursor
  until found == true or cursor == "0"

  return found
end
