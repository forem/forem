# frozen_string_literal: true

require 'puma/server'
require 'puma/const'

module Puma
  # Generic class that is used by `Puma::Cluster` and `Puma::Single` to
  # serve requests. This class spawns a new instance of `Puma::Server` via
  # a call to `start_server`.
  class Runner
    def initialize(cli, events)
      @launcher = cli
      @events = events
      @options = cli.options
      @app = nil
      @control = nil
      @started_at = Time.now
      @wakeup = nil
    end

    def wakeup!
      return unless @wakeup

      @wakeup.write "!" unless @wakeup.closed?

    rescue SystemCallError, IOError
      Puma::Util.purge_interrupt_queue
    end

    def development?
      @options[:environment] == "development"
    end

    def test?
      @options[:environment] == "test"
    end

    def log(str)
      @events.log str
    end

    # @version 5.0.0
    def stop_control
      @control.stop(true) if @control
    end

    def error(str)
      @events.error str
    end

    def debug(str)
      @events.log "- #{str}" if @options[:debug]
    end

    def start_control
      str = @options[:control_url]
      return unless str

      require 'puma/app/status'

      if token = @options[:control_auth_token]
        token = nil if token.empty? || token == 'none'
      end

      app = Puma::App::Status.new @launcher, token

      control = Puma::Server.new app, @launcher.events,
        { min_threads: 0, max_threads: 1, queue_requests: false }

      control.binder.parse [str], self, 'Starting control server'

      control.run thread_name: 'ctl'
      @control = control
    end

    # @version 5.0.0
    def close_control_listeners
      @control.binder.close_listeners if @control
    end

    # @!attribute [r] ruby_engine
    def ruby_engine
      if !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby"
        "ruby #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
      else
        if defined?(RUBY_ENGINE_VERSION)
          "#{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} - ruby #{RUBY_VERSION}"
        else
          "#{RUBY_ENGINE} #{RUBY_VERSION}"
        end
      end
    end

    def output_header(mode)
      min_t = @options[:min_threads]
      max_t = @options[:max_threads]
      environment = @options[:environment]

      log "Puma starting in #{mode} mode..."
      log "* Puma version: #{Puma::Const::PUMA_VERSION} (#{ruby_engine}) (\"#{Puma::Const::CODE_NAME}\")"
      log "*  Min threads: #{min_t}"
      log "*  Max threads: #{max_t}"
      log "*  Environment: #{environment}"

      if mode == "cluster"
        log "*   Master PID: #{Process.pid}"
      else
        log "*          PID: #{Process.pid}"
      end
    end

    def redirected_io?
      @options[:redirect_stdout] || @options[:redirect_stderr]
    end

    def redirect_io
      stdout = @options[:redirect_stdout]
      stderr = @options[:redirect_stderr]
      append = @options[:redirect_append]

      if stdout
        ensure_output_directory_exists(stdout, 'STDOUT')

        STDOUT.reopen stdout, (append ? "a" : "w")
        STDOUT.puts "=== puma startup: #{Time.now} ==="
        STDOUT.flush unless STDOUT.sync
      end

      if stderr
        ensure_output_directory_exists(stderr, 'STDERR')

        STDERR.reopen stderr, (append ? "a" : "w")
        STDERR.puts "=== puma startup: #{Time.now} ==="
        STDERR.flush unless STDERR.sync
      end

      if @options[:mutate_stdout_and_stderr_to_sync_on_write]
        STDOUT.sync = true
        STDERR.sync = true
      end
    end

    def load_and_bind
      unless @launcher.config.app_configured?
        error "No application configured, nothing to run"
        exit 1
      end

      begin
        @app = @launcher.config.app
      rescue Exception => e
        log "! Unable to load application: #{e.class}: #{e.message}"
        raise e
      end

      @launcher.binder.parse @options[:binds], self
    end

    # @!attribute [r] app
    def app
      @app ||= @launcher.config.app
    end

    def start_server
      server = Puma::Server.new app, @launcher.events, @options
      server.inherit_binder @launcher.binder
      server
    end

    private
    def ensure_output_directory_exists(path, io_name)
      unless Dir.exist?(File.dirname(path))
        raise "Cannot redirect #{io_name} to #{path}"
      end
    end
  end
end
