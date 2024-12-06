# frozen_string_literal: true

require_relative '../../core/utils/duration'
require_relative '../sample_rate'

module Datadog
  module AppSec
    module Configuration
      # Settings
      module Settings
        # rubocop:disable Layout/LineLength
        DEFAULT_OBFUSCATOR_KEY_REGEX = '(?i)(?:p(?:ass)?w(?:or)?d|pass(?:_?phrase)?|secret|(?:api_?|private_?|public_?)key)|token|consumer_?(?:id|key|secret)|sign(?:ed|ature)|bearer|authorization'
        DEFAULT_OBFUSCATOR_VALUE_REGEX = '(?i)(?:p(?:ass)?w(?:or)?d|pass(?:_?phrase)?|secret|(?:api_?|private_?|public_?|access_?|secret_?)key(?:_?id)?|token|consumer_?(?:id|key|secret)|sign(?:ed|ature)?|auth(?:entication|orization)?)(?:\s*=[^;]|"\s*:\s*"[^"]+")|bearer\s+[a-z0-9\._\-]+|token:[a-z0-9]{13}|gh[opsu]_[0-9a-zA-Z]{36}|ey[I-L][\w=-]+\.ey[I-L][\w=-]+(?:\.[\w.+\/=-]+)?|[\-]{5}BEGIN[a-z\s]+PRIVATE\sKEY[\-]{5}[^\-]+[\-]{5}END[a-z\s]+PRIVATE\sKEY|ssh-rsa\s*[a-z0-9\/\.+]{100,}'
        # rubocop:enable Layout/LineLength
        APPSEC_VALID_TRACK_USER_EVENTS_MODE = [
          'safe',
          'extended'
        ].freeze
        APPSEC_VALID_TRACK_USER_EVENTS_ENABLED_VALUES = [
          '1',
          'true'
        ].concat(APPSEC_VALID_TRACK_USER_EVENTS_MODE).freeze

        def self.extended(base)
          base = base.singleton_class unless base.is_a?(Class)
          add_settings!(base)
        end

        # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/BlockLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        def self.add_settings!(base)
          base.class_eval do
            settings :appsec do
              option :enabled do |o|
                o.type :bool
                o.env 'DD_APPSEC_ENABLED'
                o.default false
              end

              define_method(:instrument) do |integration_name|
                if enabled
                  registered_integration = Datadog::AppSec::Contrib::Integration.registry[integration_name]
                  if registered_integration
                    klass = registered_integration.klass
                    if klass.loaded? && klass.compatible?
                      instance = klass.new
                      instance.patcher.patch unless instance.patcher.patched?
                    end
                  end
                end
              end

              option :ruleset do |o|
                o.env 'DD_APPSEC_RULES'
                o.default :recommended
              end

              option :ip_denylist do |o|
                o.type :array
                o.default []
              end

              option :user_id_denylist do |o|
                o.type :array
                o.default []
              end

              option :waf_timeout do |o|
                o.env 'DD_APPSEC_WAF_TIMEOUT' # us
                o.default 5_000
                o.setter do |v|
                  Datadog::Core::Utils::Duration.call(v.to_s, base: :us)
                end
              end

              option :waf_debug do |o|
                o.env 'DD_APPSEC_WAF_DEBUG'
                o.default false
                o.type :bool
              end

              option :trace_rate_limit do |o|
                o.type :int
                o.env 'DD_APPSEC_TRACE_RATE_LIMIT' # trace/s
                o.default 100
              end

              option :obfuscator_key_regex do |o|
                o.type :string
                o.env 'DD_APPSEC_OBFUSCATION_PARAMETER_KEY_REGEXP'
                o.default DEFAULT_OBFUSCATOR_KEY_REGEX
              end

              option :obfuscator_value_regex do |o|
                o.type :string
                o.env 'DD_APPSEC_OBFUSCATION_PARAMETER_VALUE_REGEXP'
                o.default DEFAULT_OBFUSCATOR_VALUE_REGEX
              end

              settings :block do
                settings :templates do
                  option :html do |o|
                    o.env 'DD_APPSEC_HTTP_BLOCKED_TEMPLATE_HTML'
                    o.type :string, nilable: true
                    o.setter do |value|
                      if value
                        raise(ArgumentError, "appsec.templates.html: file not found: #{value}") unless File.exist?(value)

                        File.open(value, 'rb', &:read) || ''
                      end
                    end
                  end

                  option :json do |o|
                    o.env 'DD_APPSEC_HTTP_BLOCKED_TEMPLATE_JSON'
                    o.type :string, nilable: true
                    o.setter do |value|
                      if value
                        raise(ArgumentError, "appsec.templates.json: file not found: #{value}") unless File.exist?(value)

                        File.open(value, 'rb', &:read) || ''
                      end
                    end
                  end

                  option :text do |o|
                    o.env 'DD_APPSEC_HTTP_BLOCKED_TEMPLATE_TEXT'
                    o.type :string, nilable: true
                    o.setter do |value|
                      if value
                        raise(ArgumentError, "appsec.templates.text: file not found: #{value}") unless File.exist?(value)

                        File.open(value, 'rb', &:read) || ''
                      end
                    end
                  end
                end
              end

              settings :track_user_events do
                option :enabled do |o|
                  o.default true
                  o.type :bool
                  o.env 'DD_APPSEC_AUTOMATED_USER_EVENTS_TRACKING'
                  o.env_parser do |env_value|
                    if env_value == 'disabled'
                      false
                    else
                      APPSEC_VALID_TRACK_USER_EVENTS_ENABLED_VALUES.include?(env_value.strip.downcase)
                    end
                  end
                end

                option :mode do |o|
                  o.type :string
                  o.env 'DD_APPSEC_AUTOMATED_USER_EVENTS_TRACKING'
                  o.default 'safe'
                  o.setter do |v|
                    if APPSEC_VALID_TRACK_USER_EVENTS_MODE.include?(v)
                      v
                    elsif v == 'disabled'
                      'safe'
                    else
                      Datadog.logger.warn(
                        'The appsec.track_user_events.mode value provided is not supported.' \
                        'Supported values are: safe | extended.' \
                        'Using default value `safe`'
                      )
                      'safe'
                    end
                  end
                end
              end

              settings :api_security do
                option :enabled do |o|
                  o.type :bool
                  o.env 'DD_EXPERIMENTAL_API_SECURITY_ENABLED'
                  o.default false
                end

                option :sample_rate do |o|
                  o.type :float
                  o.env 'DD_API_SECURITY_REQUEST_SAMPLE_RATE'
                  o.default 0.1
                  o.setter do |value|
                    value = 1 if value > 1
                    SampleRate.new(value)
                  end
                end
              end
            end
          end
        end
        # rubocop:enable Metrics/AbcSize,Metrics/MethodLength,Metrics/BlockLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      end
    end
  end
end
