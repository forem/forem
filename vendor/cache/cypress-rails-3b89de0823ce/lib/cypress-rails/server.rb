# frozen_string_literal: true

require "uri"
require "net/http"
require "rack"
require_relative "initializer_hooks"
require_relative "server/middleware"
require_relative "server/checker"
require_relative "server/timer"
require_relative "server/puma"

module CypressRails
  class Server
    class << self
      def ports
        @ports ||= {}
      end
    end

    attr_reader :app, :host, :port

    def initialize(app,
      host:,
      port:,
      reportable_errors: [Exception],
      extra_middleware: [])
      @app = app
      @extra_middleware = extra_middleware
      @server_thread = nil # suppress warnings
      @host = host
      @reportable_errors = reportable_errors
      @port = port
      @port ||= Server.ports[port_key]
      @port ||= find_available_port(host)
      @checker = Checker.new(@host, @port)
      @initializer_hooks = InitializerHooks.instance
    end

    def reset_error!
      middleware.clear_error
    end

    def error
      middleware.error
    end

    def using_ssl?
      @checker.ssl?
    end

    def responsive?
      return false if @server_thread&.join(0)

      res = @checker.request { |http| http.get("/__identify__") }

      return res.body == app.object_id.to_s if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)
    rescue SystemCallError, Net::ReadTimeout, OpenSSL::SSL::SSLError
      false
    end

    def wait_for_pending_requests
      timer = Timer.new(60)
      while pending_requests?
        raise "Requests did not finish in 60 seconds: #{middleware.pending_requests}" if timer.expired?

        sleep 0.01
      end
    end

    def boot
      unless responsive?
        Server.ports[port_key] = port

        @server_thread = Thread.new {
          Puma.create(middleware, port, host)
        }

        timer = Timer.new(60)
        until responsive?
          raise "Rack application timed out during boot" if timer.expired?

          @server_thread.join(0.1)
          @initializer_hooks.run(:after_server_start)
        end
      end

      self
    end

    private

    def middleware
      @middleware ||= Middleware.new(app, @reportable_errors, @extra_middleware)
    end

    def port_key
      app.object_id # as opposed to middleware.object_id if multiple instances
    end

    def pending_requests?
      middleware.pending_requests?
    end

    def find_available_port(host)
      server = TCPServer.new(host, 0)
      port = server.addr[1]
      server.close

      # Workaround issue where some platforms (mac, ???) when passed a host
      # of '0.0.0.0' will return a port that is only available on one of the
      # ip addresses that resolves to, but the next binding to that port requires
      # that port to be available on all ips
      server = TCPServer.new(host, port)
      port
    rescue Errno::EADDRINUSE
      retry
    ensure
      server&.close
    end
  end
end
