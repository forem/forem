module Guard
  class RSpec < Plugin
    class Deprecator
      attr_accessor :options

      def self.warns_about_deprecated_options(options = {})
        new(options).warns_about_deprecated_options
      end

      def initialize(options = {})
        @options = options
      end

      def warns_about_deprecated_options
        _spec_opts_env
        _version_option
        _exclude_option
        _use_cmd_option
        _keep_failed_option
        _focus_on_failed_option
      end

      private

      def _spec_opts_env
        return if ENV["SPEC_OPTS"].nil?
        Compat::UI.warning(
          "The SPEC_OPTS environment variable is present." \
          " This can conflict with guard-rspec."
        )
      end

      def _version_option
        return unless options.key?(:version)
        _deprecated(
          "The :version option is deprecated." \
          " Only RSpec ~> 2.14 is now supported."
        )
      end

      def _exclude_option
        return unless options.key?(:exclude)
        _deprecated(
          "The :exclude option is deprecated." \
          " Please Guard ignore method instead." \
          " https://github.com/guard/guard#ignore"
        )
      end

      def _use_cmd_option
        %w(color drb fail_fast formatter env bundler
           binstubs rvm cli spring turnip zeus foreman).each do |option|
          next unless options.key?(option.to_sym)
          _deprecated(
            "The :#{option} option is deprecated." \
            " Please customize the new :cmd option to fit your need."
          )
        end
      end

      def _keep_failed_option
        return unless options.key?(:keep_failed)
        _deprecated(
          "The :keep_failed option is deprecated." \
          " Please set new :failed_mode option value to" \
          " :keep instead." \
          " https://github.com/guard/guard-rspec#list-of-available-options"
        )
      end

      def _focus_on_failed_option
        return unless options.key?(:focus_on_failed)
        _deprecated(
          "The :focus_on_failed option is deprecated." \
          " Please set new :failed_mode option value to" \
          " :focus instead." \
          " https://github.com/guard/guard-rspec#list-of-available-options"
        )
      end

      def _deprecated(message)
        Compat::UI.warning %(Guard::RSpec DEPRECATION WARNING: #{message})
      end
    end
  end
end
