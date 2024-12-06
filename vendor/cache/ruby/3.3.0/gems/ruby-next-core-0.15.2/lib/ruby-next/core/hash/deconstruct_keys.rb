# frozen_string_literal: true

RubyNext::Core.patch Hash, method: :deconstruct_keys, version: "2.7" do
  <<-RUBY
def deconstruct_keys(_)
  self
end
  RUBY
end

# We need to hack `respond_to?` in Ruby 2.5, since it's not working with refinements
if Gem::Version.new(::RubyNext.current_ruby_version) < Gem::Version.new("2.6")
  RubyNext::Core.patch refineable: Hash, name: "HashRespondToDeconstructKeys", method: :deconstruct_keys, version: "2.7" do
    <<-RUBY
def respond_to?(mid, *)
  return true if mid == :deconstruct_keys
  super
end
    RUBY
  end
end
