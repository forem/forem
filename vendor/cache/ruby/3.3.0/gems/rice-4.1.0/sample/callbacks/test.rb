require 'sample_callbacks'

def hello(message)
  "Hello #{message}"
end

cb1 = CallbackHolder.new
cb2 = CallbackHolder.new
cb3 = CallbackHolder.new

cb1.register_callback(lambda do |param|
  "Callback 1 got param #{param}"
end)

cb2.register_callback(lambda do |param|
  "Callback 2 got param #{param}"
end)

cb3.register_callback method(:hello)

puts "Calling Callback 1"
puts cb1.fire_callback("Hello")

puts "Calling Callback 2"
puts cb2.fire_callback("World")

puts "Calling Callback 3"
puts cb3.fire_callback("Ruby")
