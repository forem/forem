# Deliberately named _specs.rb to avoid being loaded except when specified

RSpec.configure do |c|
  c.register_ordering(:shuffled, &:shuffle)
end

RSpec.describe "Group", :order => :shuffled do
  10.times do |i|
    it("passes #{i}") {      }
    it("fails #{i}")  { fail }
  end
end
