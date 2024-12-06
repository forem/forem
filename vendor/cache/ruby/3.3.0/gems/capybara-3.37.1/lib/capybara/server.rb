# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'rack'
require 'capybara/server/middleware'
require 'capybara/server/animation_disabler'
require 'capybara/server/checker'

module Capybara
  # @api private
  class Server
    class << self
      def ports
        @ports ||= {}
      end
    end

    attr_reader :app, :port, :host

    def initialize(app,
                   *deprecated_options,
                   port: Capybara.server_port,
                   host: Capybara.server_host,
                   reportable_errors: Capybara.server_errors,
                   extra_middleware: [])
      unless deprecated_options.empty?
        warn 'Positional arguments, other than the application, to Server#new are deprecated, please use keyword arguments'
      end
      @app = app
      @extra_middleware = extra_middleware
      @server_thread = nil # suppress warnings
      @host = deprecated_options[1] || host
      @reportable_errors = deprecated_options[2] || reportable_errors
      @port = deprecated_options[0] || port
      @port ||= Capybara::Server.ports[port_key]
      @port ||= find_available_port(host)
      @checker = Checker.new(@host, @port)
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

      res = @checker.request { |http| http.get('/__identify__') }

      return res.body == app.object_id.to_s if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)
    rescue SystemCallError, Net::ReadTimeout, OpenSSL::SSL::SSLError
      false
    end

    def wait_for_pending_requests
      timer = Capybara::Helpers.timer(expire_in: 60)
      while pending_requests?
        raise "Requests did not finish in 60 seconds: #{middleware.pending_requests}" if timer.expired?

        sleep 0.01
      end
    end

    def boot
      unless responsive?
        Capybara::Server.ports[port_key] = port

        @server_thread = Thread.new do
          Capybara.server.call(middleware, port, host)
        end

        timer = Capybara::Helpers.timer(expire_in: 60)
        until responsive?
          raise 'Rack application timed out during boot' if timer.expired?

          @server_thread.join(0.1)
        end
      end

      self
    end

    def base_url
      "http#{'s' if using_ssl?}://#{host}:#{port}"
    end

  private

    def middleware
      @middleware ||= Middleware.new(app, @reportable_errors, @extra_middleware)
    end

    def port_key
      Capybara.reuse_server ? app.object_id : middleware.object_id
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
