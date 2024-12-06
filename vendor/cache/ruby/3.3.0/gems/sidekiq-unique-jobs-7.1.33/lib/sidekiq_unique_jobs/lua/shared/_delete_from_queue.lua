local function delete_from_queue(queue, digest)
  local per    = 50
  local total  = redis.call("LLEN", queue)
  local index  = 0
  local result = nil

  while (index < total) do
    local items = redis.call("LRANGE", queue, index, index + per -1)
    if #items == 0 then
      break
    end
    for _, item in pairs(items) do
      if string.find(item, digest) then
        redis.call("LREM", queue, 1, item)
        result = item
        break
      end
    end
    index = index + per
  end
  return result
end
