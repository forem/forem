# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Linter
    class << self
      attr_accessor :simple_name
      attr_accessor :config_schema

      # When defining a Linter class, define its simple name as well. This
      # assumes that the module hierarchy of every linter starts with
      # `ERBLint::Linters::`, and removes this part of the class name.
      #
      # `ERBLint::Linters::Foo.simple_name`          #=> "Foo"
      # `ERBLint::Linters::Compass::Bar.simple_name` #=> "Compass::Bar"
      def inherited(linter)
        super
        linter.simple_name = if linter.name.start_with?('ERBLint::Linters::')
          name_parts = linter.name.split('::')
          name_parts[2..-1].join('::')
        else
          linter.name
        end

        linter.config_schema = LinterConfig
      end

      def support_autocorrect?
        method_defined?(:autocorrect)
      end
    end

    attr_reader :offenses

    # Must be implemented by the concrete inheriting class.
    def initialize(file_loader, config)
      @file_loader = file_loader
      @config = config
      raise ArgumentError, "expect `config` to be #{self.class.config_schema} instance, "\
        "not #{config.class}" unless config.is_a?(self.class.config_schema)
      @offenses = []
    end

    def enabled?
      @config.enabled?
    end

    def excludes_file?(filename)
      @config.excludes_file?(filename)
    end

    def run(_processed_source)
      raise NotImplementedError, "must implement ##{__method__}"
    end

    def add_offense(source_range, message, context = nil)
      @offenses << Offense.new(self, source_range, message, context)
    end

    def clear_offenses
      @offenses = []
    end
  end
end
