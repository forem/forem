module Rpush
  @reflection_stack ||= [ReflectionCollection.new]

  class << self
    attr_reader :reflection_stack
  end

  def self.reflect
    yield reflection_stack[0] if block_given?
  end
end
