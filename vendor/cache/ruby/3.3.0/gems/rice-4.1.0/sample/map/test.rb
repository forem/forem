require_relative 'map.so'
m = Std::Map.new
m[0] = 1
m[1] = 2
m[3] = 3
m.each { |x| p x }

