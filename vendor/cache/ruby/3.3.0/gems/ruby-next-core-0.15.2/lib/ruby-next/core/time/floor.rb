# frozen_string_literal: true

RubyNext::Core.patch Time, method: :floor, version: "2.7" do
  <<-RUBY
def floor(den = 0)
  self - (subsec % (10**-den))
end
  RUBY
end
