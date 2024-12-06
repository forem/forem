local function current_time()
  local time = redis.call("time")
  local s = time[1]
  local ms = time[2]
  local number = tonumber((s .. "." .. ms))

  return number
end
