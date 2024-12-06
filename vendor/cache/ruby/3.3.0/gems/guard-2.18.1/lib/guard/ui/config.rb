require "guard/options"
require "guard/ui/logger"

module Guard
  module UI
    class Config < Guard::Options
      DEFAULTS = {
        only: nil,
        except: nil,

        # nil (will be whatever $stderr is later) or LumberJack device, e.g.
        # $stderr or 'foo.log'
        device: nil,
      }.freeze

      DEPRECATED_OPTS = %w(template time_format level progname).freeze

      attr_reader :logger_config

      def initialize(options = {})
        opts = Guard::Options.new(options, DEFAULTS)

        # migrate old options stored in UI config directly
        deprecated_logger_opts = {}
        DEPRECATED_OPTS.each do |option|
          if opts.key?(option)
            deprecated_logger_opts[option.to_sym] = opts.delete(option)
          end
        end

        @logger_config = Logger::Config.new(deprecated_logger_opts)
        super(opts.to_hash)
      end

      def device
        # Use strings to work around Thor's indifferent Hash's bug
        fetch("device") || $stderr
      end

      def only
        fetch("only")
      end

      def except
        fetch("except")
      end

      def [](name)
        name = name.to_s

        # TODO: remove in Guard 3.x
        return logger_config[name] if DEPRECATED_OPTS.include?(name)
        return device if name == "device"

        # let Thor's Hash handle anything else
        super(name.to_s)
      end

      def with_progname(name)
        if Guard::UI.logger.respond_to?(:set_progname)
          Guard::UI.logger.set_progname(name) do
            yield if block_given?
          end
        elsif block_given?
          yield
        end
      end
    end
  end
end
