# frozen_string_literal: true

RubyNext::Core.patch Array, method: :deconstruct, version: "2.7" do
  <<-RUBY
def deconstruct
  self
end
  RUBY
end

# We need to hack `respond_to?` in Ruby 2.5, since it's not working with refinements
if Gem::Version.new(::RubyNext.current_ruby_version) < Gem::Version.new("2.6")
  RubyNext::Core.patch refineable: Array, name: "ArrayRespondToDeconstruct", method: :deconstruct, version: "2.7" do
    <<-RUBY
def respond_to?(mid, *)
  return true if mid == :deconstruct
  super
end
    RUBY
  end
end
