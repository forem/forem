# frozen_string_literal: true

module Sidekiq # :nodoc:
  module Extensions
    def self.enable_delay!
      warn "Sidekiq's Delayed Extensions will be removed in Sidekiq 7.0", uplevel: 1

      if defined?(::ActiveSupport)
        require "sidekiq/extensions/active_record"
        require "sidekiq/extensions/action_mailer"

        # Need to patch Psych so it can autoload classes whose names are serialized
        # in the delayed YAML.
        Psych::Visitors::ToRuby.prepend(Sidekiq::Extensions::PsychAutoload)

        ActiveSupport.on_load(:active_record) do
          include Sidekiq::Extensions::ActiveRecord
        end
        ActiveSupport.on_load(:action_mailer) do
          extend Sidekiq::Extensions::ActionMailer
        end
      end

      require "sidekiq/extensions/class_methods"
      Module.__send__(:include, Sidekiq::Extensions::Klass)
    end

    module PsychAutoload
      def resolve_class(klass_name)
        return nil if !klass_name || klass_name.empty?
        # constantize
        names = klass_name.split("::")
        names.shift if names.empty? || names.first.empty?

        names.inject(Object) do |constant, name|
          constant.const_defined?(name) ? constant.const_get(name) : constant.const_missing(name)
        end
      rescue NameError
        super
      end
    end
  end
end
