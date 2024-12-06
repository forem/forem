@retained = String.new("")
1_000_000.times.map { @retained << "A" }

load File.join(__dir__, "load_child.rb")

