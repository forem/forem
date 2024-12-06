# frozen_string_literal: true

RubyNext::Core.patch Hash, method: :merge, version: "2.6", supported: {}.method(:merge).arity < 0, core_ext: :prepend do
  <<-RUBY
def merge(*others)
  return super if others.size == 1
  return dup if others.size == 0

  merge(others.shift).tap do |new_h|
    others.each { |h| new_h.merge!(h) }
  end
end
  RUBY
end
