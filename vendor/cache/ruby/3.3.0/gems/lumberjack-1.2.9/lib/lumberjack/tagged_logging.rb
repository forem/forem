# frozen_string_literal: true

module Lumberjack
  # Monkey patch for ActiveSupport::TaggedLogger so it doesn't blow up when
  # a Lumberjack logger is trying to be wrapped. This module will be automatically
  # included in ActiveSupport::TaggedLogger if activesupport is already loaded.
  module TaggedLogging
    class << self
      def included(base)
        base.singleton_class.send(:prepend, ClassMethods)
      end
    end

    module ClassMethods
      def new(logger)
        if logger.is_a?(Lumberjack::Logger)
          logger = logger.tagged_logger! unless logger.respond_to?(:tagged)
          logger
        else
          super
        end
      end
    end
  end
end

if defined?(ActiveSupport::TaggedLogging)
  ActiveSupport::TaggedLogging.include(Lumberjack::TaggedLogging)
end
