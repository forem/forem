# frozen_string_literal: true

RubyNext::Core.patch Time, method: :ceil, version: "2.7" do
  <<-RUBY
def ceil(den = 0)
  sceil = (subsec * 10**den).ceil.to_r / 10**den
  change = sceil - subsec
  self + change
end
  RUBY
end
