local function delete_from_sorted_set(name, digest)
  local per   = 50
  local total = redis.call("zcard", name)
  local index = 0
  local result
  while (index < total) do
    local items = redis.call("ZRANGE", name, index, index + per -1)
    for _, item in pairs(items) do
      if string.find(item, digest) then
        redis.call("ZREM", name, item)
        result = item
        break
      end
    end
    index = index + per
  end
  return result
end
