require "json"
require "ipaddr"
require "securerandom"
require "set"
require "rack"

module BetterErrors
  # Better Errors' error handling middleware. Including this in your middleware
  # stack will show a Better Errors error page for exceptions raised below this
  # middleware.
  #
  # If you are using Ruby on Rails, you do not need to manually insert this
  # middleware into your middleware stack.
  #
  # @example Sinatra
  #   require "better_errors"
  #
  #   if development?
  #     use BetterErrors::Middleware
  #   end
  #
  # @example Rack
  #   require "better_errors"
  #   if ENV["RACK_ENV"] == "development"
  #     use BetterErrors::Middleware
  #   end
  #
  class Middleware
    # The set of IP addresses that are allowed to access Better Errors.
    #
    # Set to `{ "127.0.0.1/8", "::1/128" }` by default.
    ALLOWED_IPS = Set.new

    # Adds an address to the set of IP addresses allowed to access Better
    # Errors.
    def self.allow_ip!(addr)
      ALLOWED_IPS << (addr.is_a?(IPAddr) ? addr : IPAddr.new(addr))
    end

    allow_ip! "127.0.0.0/8"
    allow_ip! "::1/128" rescue nil # windows ruby doesn't have ipv6 support

    CSRF_TOKEN_COOKIE_NAME = "BetterErrors-#{BetterErrors::VERSION}-CSRF-Token"

    # A new instance of BetterErrors::Middleware
    #
    # @param app      The Rack app/middleware to wrap with Better Errors
    # @param handler  The error handler to use.
    def initialize(app, handler = ErrorPage)
      @app      = app
      @handler  = handler
    end

    # Calls the Better Errors middleware
    #
    # @param [Hash] env
    # @return [Array]
    def call(env)
      if allow_ip? env
        better_errors_call env
      else
        @app.call env
      end
    end

  private

    def allow_ip?(env)
      request = Rack::Request.new(env)
      return true unless request.ip and !request.ip.strip.empty?
      ip = IPAddr.new request.ip.split("%").first
      ALLOWED_IPS.any? { |subnet| subnet.include? ip }
    end

    def better_errors_call(env)
      case env["PATH_INFO"]
      when %r{/__better_errors/(?<id>.+?)/(?<method>\w+)\z}
        internal_call(env, $~[:id], $~[:method])
      when %r{/__better_errors/?\z}
        show_error_page env
      else
        protected_app_call env
      end
    end

    def protected_app_call(env)
      @app.call env
    rescue Exception => ex
      @error_page = @handler.new ex, env
      log_exception
      show_error_page(env, ex)
    end

    def show_error_page(env, exception=nil)
      request = Rack::Request.new(env)
      csrf_token = request.cookies[CSRF_TOKEN_COOKIE_NAME] || SecureRandom.uuid
      csp_nonce = SecureRandom.base64(12)

      type, content = if @error_page
        if text?(env)
          [ 'plain', @error_page.render_text ]
        else
          [ 'html', @error_page.render_main(csrf_token, csp_nonce) ]
        end
      else
        [ 'html', no_errors_page ]
      end

      status_code = 500
      if defined?(ActionDispatch::ExceptionWrapper) && exception
        status_code = ActionDispatch::ExceptionWrapper.new(env, exception).status_code
      end

      headers = {
        "Content-Type" => "text/#{type}; charset=utf-8",
        "Content-Security-Policy" => [
          "default-src 'none'",
          # Specifying nonce makes a modern browser ignore 'unsafe-inline' which could still be set 
          # for older browsers without nonce support.
          # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/script-src
          "script-src 'self' 'nonce-#{csp_nonce}' 'unsafe-inline'",
          "style-src 'self' 'nonce-#{csp_nonce}' 'unsafe-inline'",
          "img-src data:",
          "connect-src 'self'",
          "navigate-to 'self' #{BetterErrors.editor.scheme}",
        ].join('; '),
      }

      response = Rack::Response.new(content, status_code, headers)

      unless request.cookies[CSRF_TOKEN_COOKIE_NAME]
        response.set_cookie(CSRF_TOKEN_COOKIE_NAME, value: csrf_token, path: "/", httponly: true, same_site: :strict)
      end

      # In older versions of Rack, the body returned here is actually a Rack::BodyProxy which seems to be a bug.
      # (It contains status, headers and body and does not act like an array of strings.)
      # Since we already have status code and body here, there's no need to use the ones in the Rack::Response.
      (_status_code, headers, _body) = response.finish
      [status_code, headers, [content]]
    end

    def text?(env)
      env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest" ||
        !env["HTTP_ACCEPT"].to_s.include?('html')
    end

    def log_exception
      return unless BetterErrors.logger

      message = "\n#{@error_page.exception_type} - #{@error_page.exception_message}:\n"
      message += backtrace_frames.map { |frame| "  #{frame}\n" }.join

      BetterErrors.logger.fatal message
    end

    def backtrace_frames
      if defined?(Rails) && defined?(Rails.backtrace_cleaner)
        Rails.backtrace_cleaner.clean @error_page.backtrace_frames.map(&:to_s)
      else
        @error_page.backtrace_frames
      end
    end

    def internal_call(env, id, method)
      return not_found_json_response unless %w[variables eval].include?(method)
      return no_errors_json_response unless @error_page
      return invalid_error_json_response if id != @error_page.id

      request = Rack::Request.new(env)
      return invalid_csrf_token_json_response unless request.cookies[CSRF_TOKEN_COOKIE_NAME]

      request.body.rewind
      body = JSON.parse(request.body.read)
      return invalid_csrf_token_json_response unless request.cookies[CSRF_TOKEN_COOKIE_NAME] == body['csrfToken']

      return not_acceptable_json_response unless request.content_type == 'application/json'

      response = @error_page.send("do_#{method}", body)
      [200, { "Content-Type" => "application/json; charset=utf-8" }, [JSON.dump(response)]]
    end

    def no_errors_page
      "<h1>No errors</h1><p>No errors have been recorded yet.</p><hr>" +
      "<code>Better Errors v#{BetterErrors::VERSION}</code>"
    end

    def no_errors_json_response
      explanation = if defined? Middleman
        "Middleman reloads all dependencies for each request, " +
          "which breaks Better Errors."
      elsif defined?(Shotgun) && defined?(Hanami)
        "Hanami is likely running with code-reloading enabled, which is the default. " +
          "You can disable this by running hanami with the `--no-code-reloading` option."
      elsif defined? Shotgun
        "The shotgun gem causes everything to be reloaded for every request. " +
          "You can disable shotgun in the Gemfile temporarily to use Better Errors."
      else
        "The application has been restarted since this page loaded, " +
          "or the framework is reloading all gems before each request "
      end
      [200, { "Content-Type" => "application/json; charset=utf-8" }, [JSON.dump(
        error: 'No exception information available',
        explanation: explanation,
      )]]
    end

    def invalid_error_json_response
      [200, { "Content-Type" => "application/json; charset=utf-8" }, [JSON.dump(
        error: "Session expired",
        explanation: "This page was likely opened from a previous exception, " +
          "and the exception is no longer available in memory.",
      )]]
    end

    def invalid_csrf_token_json_response
      [200, { "Content-Type" => "application/json; charset=utf-8" }, [JSON.dump(
        error: "Invalid CSRF Token",
        explanation: "The browser session might have been cleared, " +
          "or something went wrong.",
      )]]
    end

    def not_found_json_response
      [404, { "Content-Type" => "application/json; charset=utf-8" }, [JSON.dump(
        error: "Not found",
        explanation: "Not a recognized internal call.",
      )]]
    end

    def not_acceptable_json_response
      [406, { "Content-Type" => "application/json; charset=utf-8" }, [JSON.dump(
        error: "Request not acceptable",
        explanation: "The internal request did not match an acceptable content type.",
      )]]
    end
  end
end
