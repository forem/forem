# frozen_string_literal: true

RubyNext::Core.patch String, method: :split, version: "2.6", supported: ("a b".split(" ", &proc {}) == "a b"), core_ext: :prepend do
  <<-RUBY
def split(*args, &block)
  return super unless block_given?
  super.each { |el| yield el }
  self
end
  RUBY
end
