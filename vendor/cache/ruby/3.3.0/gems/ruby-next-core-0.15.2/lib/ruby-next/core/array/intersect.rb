# frozen_string_literal: true

RubyNext::Core.patch Array, method: :intersect?, version: "3.1" do
  <<-RUBY
def intersect?(other)
  !(self & other).empty?
end
  RUBY
end
