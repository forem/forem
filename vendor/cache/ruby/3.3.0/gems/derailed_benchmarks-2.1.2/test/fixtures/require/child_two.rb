class ChildTwo
  @retained = String.new("")
  200_000.times.map { @retained << "A" }
end

begin
  require File.expand_path('../raise_child.rb', __FILE__)
rescue
end
