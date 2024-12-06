# frozen_string_literal: true
module SmartProperties
  module Validations
    class Ancestor
      include SmartProperties

      property! :type, accepts: ->(type) { type.is_a?(Class) }

      def validate(klass)
        klass.is_a?(Class) && klass < type
      end

      def to_proc
        validator = self
        ->(klass) { validator.validate(klass) }
      end

      def to_s
        "subclasses of #{type.to_s}"
      end

      class << self
        alias_method :must_be, :new
      end
    end
  end
end
