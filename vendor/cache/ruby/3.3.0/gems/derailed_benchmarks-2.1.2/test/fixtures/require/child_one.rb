class ChildOne
  @retained = String.new("")
  50_000.times.map { @retained << "A" }
end
