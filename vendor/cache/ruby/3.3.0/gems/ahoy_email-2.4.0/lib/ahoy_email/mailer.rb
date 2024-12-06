module AhoyEmail
  module Mailer
    extend ActiveSupport::Concern

    included do
      attr_writer :ahoy_options
      after_action :save_ahoy_options
    end

    class_methods do
      def has_history(**options)
        set_ahoy_options(options, :message)
      end

      def utm_params(**options)
        set_ahoy_options(options, :utm_params)
      end

      def track_clicks(**options)
        raise ArgumentError, "missing keyword: :campaign" unless options.key?(:campaign)
        set_ahoy_options(options, :click)
      end

      private

      def set_ahoy_options(options, key)
        allowed_keywords = AhoyEmail::Utils::OPTION_KEYS[key]
        action_keywords = [:only, :except, :if, :unless]

        unknown_keywords = options.keys - allowed_keywords - action_keywords
        raise ArgumentError, "unknown keywords: #{unknown_keywords.map(&:inspect).join(", ")}" if unknown_keywords.any?

        # use before_action, since after_action reverses order
        # https://github.com/rails/rails/issues/27261
        # callable options aren't run until save_ahoy_options after_action
        before_action(options.slice(*action_keywords)) do
          self.ahoy_options = ahoy_options.merge(key => true).merge(options.slice(*allowed_keywords))
        end
      end
    end

    def ahoy_options
      @ahoy_options ||= AhoyEmail.default_options
    end

    def save_ahoy_options
      Safely.safely do
        options = {}
        call_ahoy_options(options, :message)
        call_ahoy_options(options, :utm_params)
        call_ahoy_options(options, :click)

        if options[:message] || options[:utm_params] || options[:click]
          AhoyEmail::Processor.new(self, options).perform
        end
      end
    end

    def call_ahoy_options(options, key)
      v = ahoy_options[key]
      options[key] = v.respond_to?(:call) ? instance_exec(&v) : v

      # only call other options if needed
      if options[key]
        AhoyEmail::Utils::OPTION_KEYS[key].each do |k|
          # make sure html5 only called once
          next if options.key?(k)

          v = ahoy_options[k]
          options[k] = v.respond_to?(:call) ? instance_exec(&v) : v
        end
      end
    end
  end
end
