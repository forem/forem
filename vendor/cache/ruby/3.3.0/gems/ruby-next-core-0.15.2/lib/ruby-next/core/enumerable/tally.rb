# frozen_string_literal: true

# Ruby 3.1 adds an ability to pass a hash as accumulator.
#
# NOTE: We have separate patches for MRI 3.0+ and others due to the unsupported refinements vs modules behaviour.
if Enumerable.method_defined?(:tally) && ([].method(:tally).arity == 0) && !(defined?(JRUBY_VERSION) || defined?(TruffleRuby))
  RubyNext::Core.patch name: "TallyWithHash", supported: false, native: nil, method: :tally, version: "3.1", refineable: [Enumerable] do
    <<-'RUBY'
  def tally(*attrs)
    return super() if attrs.size.zero?

    raise ArgumentError, "wrong number of arguments (given #{attrs.size}, expected 0..1)" if attrs.size > 1

    hash = attrs.size.zero? ? {} : attrs[0].to_hash
    raise FrozenError, "can't modify frozen #{hash.class}: #{hash}" if hash.frozen?

    each_with_object(hash) do |v, acc|
      acc[v] = 0 unless acc.key?(v)
      acc[v] += 1
    end
  end
    RUBY
  end
else
  RubyNext::Core.patch Enumerable, method: :tally, version: "3.1", refineable: [Enumerable, Array] do
    <<-'RUBY'
  def tally(acc = {})
    hash = acc.to_hash
    raise FrozenError, "can't modify frozen #{hash.class}: #{hash}" if hash.frozen?

    each_with_object(hash) do |v, acc|
      acc[v] = 0 unless acc.key?(v)
      acc[v] += 1
    end
  end
    RUBY
  end
end

# This patch is intended for core extensions only (since we can not use prepend here)
RubyNext::Core.patch Enumerable, name: "TallyWithHashCoreExt", version: "3.1", supported: Enumerable.method_defined?(:tally) && ([].method(:tally).arity != 0), method: :tally, refineable: [] do
  <<-'RUBY'
def tally(acc = {})
  hash = acc.to_hash
  raise FrozenError, "can't modify frozen #{hash.class}: #{hash}" if hash.frozen?

  each_with_object(hash) do |v, acc|
    acc[v] = 0 unless acc.key?(v)
    acc[v] += 1
  end
end
  RUBY
end
