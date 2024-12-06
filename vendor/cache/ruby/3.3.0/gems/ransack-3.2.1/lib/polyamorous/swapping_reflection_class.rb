module Polyamorous
  module SwappingReflectionClass
    def swapping_reflection_klass(reflection, klass)
      new_reflection = reflection.clone
      new_reflection.instance_variable_set(:@options, reflection.options.clone)
      new_reflection.options.delete(:polymorphic)
      new_reflection.instance_variable_set(:@klass, klass)
      yield new_reflection
    end
  end
end
