@retained = String.new("")
1_000_000.times.map { @retained << "A" }

module AutoLoadChild
end
