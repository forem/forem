module CypressRails
  class Server
    module Puma
      def self.create(app, port, host)
        require "rack/handler/puma"

        # If we just run the Puma Rack handler it installs signal handlers which prevent us from being able to interrupt tests.
        # Therefore construct and run the Server instance ourselves.
        # Rack::Handler::Puma.run(app, { Host: host, Port: port, Threads: "0:4", workers: 0, daemon: false }.merge(options))
        default_options = {Host: host, Port: port, Threads: "0:4", workers: 0, daemon: false}
        options = default_options # .merge(options)

        conf = Rack::Handler::Puma.config(app, options)
        conf.clamp
        logger = (defined?(::Puma::LogWriter) ? ::Puma::LogWriter : ::Puma::Events).stdio

        puma_ver = Gem::Version.new(::Puma::Const::PUMA_VERSION)
        require_relative "patches/puma_ssl" if (Gem::Version.new("4.0.0")...Gem::Version.new("4.1.0")).cover? puma_ver

        logger.log "Starting Puma..."
        logger.log "* Version #{::Puma::Const::PUMA_VERSION} , codename: #{::Puma::Const::CODE_NAME}"
        logger.log "* Min threads: #{conf.options[:min_threads]}, max threads: #{conf.options[:max_threads]}"

        ::Puma::Server.new(conf.app, defined?(::Puma::LogWriter) ? nil : logger, conf.options).tap do |s|
          s.binder.parse conf.options[:binds], s.respond_to?(:log_writer) ? s.log_writer : s.events
          s.min_threads, s.max_threads = conf.options[:min_threads], conf.options[:max_threads] if s.respond_to?(:min_threads=)
        end.run.join
      end
    end
  end
end
