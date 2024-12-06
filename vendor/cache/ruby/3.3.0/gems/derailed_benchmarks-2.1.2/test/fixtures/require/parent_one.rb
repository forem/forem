class ParentOne
  @retained = String.new("")
  1_000_000.times.map { @retained << "A" }
end
require File.expand_path('../child_one.rb', __FILE__)
require File.expand_path('../child_two.rb', __FILE__)
require_relative 'relative_child'
require_relative File.expand_path('relative_child_two', __dir__)
