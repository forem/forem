# frozen_string_literal: true

RubyNext::Core.patch Array, method: :union, version: "2.6" do
  <<-RUBY
def union(*others)
  others.reduce(Array.new(self).uniq) { |acc, arr| acc | arr }
end
  RUBY
end

RubyNext::Core.patch Array, method: :difference, version: "2.6" do
  <<-RUBY
def difference(*others)
  others.reduce(Array.new(self)) { |acc, arr| acc - arr }
end
  RUBY
end

RubyNext::Core.patch Array, method: :intersection, version: "2.7" do
  <<-RUBY
def intersection(*others)
  others.reduce(Array.new(self)) { |acc, arr| acc & arr }
end
  RUBY
end
