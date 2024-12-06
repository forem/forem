require_relative 'animals'

[ Bear, Dog, Rabbit].each do |klass|
  animal = klass.new
  puts "A #{animal.name} says: #{animal.speak}"
end

