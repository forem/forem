@retained = String.new("")
1_000_000.times.map { @retained << "A" }

autoload :AutoLoadChild, File.join(__dir__, 'autoload_child.rb')

if AutoLoadChild
  # yay
end
