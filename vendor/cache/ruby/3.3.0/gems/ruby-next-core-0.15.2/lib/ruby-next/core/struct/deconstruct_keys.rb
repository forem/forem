# frozen_string_literal: true

# Source: https://github.com/ruby/ruby/blob/b76a21aa45fff75909a66f8b20fc5856705f7862/struct.c#L953-L980
RubyNext::Core.patch Struct, method: :deconstruct_keys, version: "2.7" do
  <<-'RUBY'
def deconstruct_keys(keys)
  raise TypeError, "wrong argument type #{keys.class} (expected Array or nil)" if keys && !keys.is_a?(Array)

  return to_h unless keys

  keys.each_with_object({}) do |k, acc|
    # if k is Symbol and not a member of a Struct return {}
    return {} if (Symbol === k || String === k) && !members.include?(k.to_sym)
    # if k is Integer check that index is not ouf of bounds
    return {} if Integer === k && k > size - 1
    acc[k] = self[k]
  end
end
  RUBY
end

# We need to hack `respond_to?` in Ruby 2.5, since it's not working with refinements
if Gem::Version.new(::RubyNext.current_ruby_version) < Gem::Version.new("2.6")
  RubyNext::Core.patch refineable: Struct, name: "StructRespondToDeconstruct", method: :deconstruct_keys, version: "2.7" do
    <<-RUBY
def respond_to?(mid, *)
  return true if mid == :deconstruct_keys || mid == :deconstruct
  super
end
    RUBY
  end
end
