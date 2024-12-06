module Honeybadger
  class Config
    class Mash
      KEYS = DEFAULTS.keys.map(&:to_s).freeze

      def initialize(config, prefix: nil, hash: {})
        @config = config
        @prefix = prefix
        @hash = hash
      end

      def to_hash
        hash.to_hash
      end
      alias to_h to_hash

      private

      attr_reader :config, :prefix, :hash

      def method_missing(method_name, *args, &block)
        m = method_name.to_s
        if mash?(m)
          return Mash.new(config, prefix: key(m), hash: hash)
        elsif setter?(m)
          return hash.send(:[]=, key(m).to_sym, args[0])
        elsif getter?(m)
          return get(key(m))
        end

        super
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      def mash?(method)
        key = [prefix, method.to_s + '.'].compact.join('.')
        KEYS.any? {|k| k.start_with?(key) }
      end

      def setter?(method_name)
        return false unless method_name.to_s =~ /=\z/
        key = key(method_name)
        KEYS.any? {|k| k == key }
      end

      def getter?(method_name)
        key = key(method_name)
        KEYS.any? {|k| k == key }
      end

      def key(method_name)
        parts = [prefix, method_name.to_s.chomp('=')]
        parts.compact!
        parts.join('.')
      end

      def get(key)
        k = key.to_sym
        return hash[k] if hash.has_key?(k)
        config.get(k)
      end
    end

    class Ruby < Mash
      def logger=(logger)
        hash[:logger] = logger
      end

      def logger
        get(:logger) || config.logger
      end

      def backend=(backend)
        hash[:backend] = backend
      end

      def backend
        get(:backend) || config.backend
      end

      def before_notify(action = nil, &block)
        hooks = Array(get(:before_notify)).dup

        if action && validate_before_action(action)
          hooks << action
        elsif block_given? && validate_before_action(block)
          hooks << block
        end

        hash[:before_notify] = hooks
      end

      def backtrace_filter(&block)
        if block_given?
          logger.warn('DEPRECATED: backtrace_filter is deprecated. Please use before_notify instead. See https://docs.honeybadger.io/ruby/support/v4-upgrade#backtrace_filter')
          hash[:backtrace_filter] = block if block_given?
        end

        get(:backtrace_filter)
      end

      def exception_filter(&block)
        if block_given?
          logger.warn('DEPRECATED: exception_filter is deprecated. Please use before_notify instead. See https://docs.honeybadger.io/ruby/support/v4-upgrade#exception_filter')
          hash[:exception_filter] = block
        end

        get(:exception_filter)
      end

      def exception_fingerprint(&block)
        if block_given?
          logger.warn('DEPRECATED: exception_fingerprint is deprecated. Please use before_notify instead. See https://docs.honeybadger.io/ruby/support/v4-upgrade#exception_fingerprint')
          hash[:exception_fingerprint] = block
        end

        get(:exception_fingerprint)
      end

      private

      def validate_before_action(action)
        if !action.respond_to?(:call)
          logger.warn(
            'You attempted to add a before notify hook that does not respond ' \
            'to #call. We are discarding this hook so your intended behavior ' \
            'will not occur.'
          )
          false
        elsif action.arity != 1
          logger.warn(
            'You attempted to add a before notify hook that has an arity ' \
            'other than one. We are discarding this hook so your intended ' \
            'behavior will not occur.'
          )
          false
        else
          true
        end
      end
    end
  end
end
