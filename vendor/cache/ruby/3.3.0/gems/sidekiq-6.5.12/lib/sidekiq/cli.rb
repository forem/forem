# frozen_string_literal: true

$stdout.sync = true

require "yaml"
require "singleton"
require "optparse"
require "erb"
require "fileutils"

require "sidekiq"
require "sidekiq/component"
require "sidekiq/launcher"

# module ScoutApm
# VERSION = "5.3.1"
# end
fail <<~EOM if defined?(ScoutApm::VERSION) && ScoutApm::VERSION < "5.2.0"
  
  
  scout_apm v#{ScoutApm::VERSION} is unsafe with Sidekiq 6.5. Please run `bundle up scout_apm` to upgrade to 5.2.0 or greater.
  
  
EOM

module Sidekiq # :nodoc:
  class CLI
    include Sidekiq::Component
    include Singleton unless $TESTING

    attr_accessor :launcher
    attr_accessor :environment
    attr_accessor :config

    def parse(args = ARGV.dup)
      @config = Sidekiq
      @config[:error_handlers].clear
      @config[:error_handlers] << @config.method(:default_error_handler)

      setup_options(args)
      initialize_logger
      validate!
    end

    def jruby?
      defined?(::JRUBY_VERSION)
    end

    # Code within this method is not tested because it alters
    # global process state irreversibly.  PRs which improve the
    # test coverage of Sidekiq::CLI are welcomed.
    def run(boot_app: true)
      boot_application if boot_app

      if environment == "development" && $stdout.tty? && @config.log_formatter.is_a?(Sidekiq::Logger::Formatters::Pretty)
        print_banner
      end
      logger.info "Booted Rails #{::Rails.version} application in #{environment} environment" if rails_app?

      self_read, self_write = IO.pipe
      sigs = %w[INT TERM TTIN TSTP]
      # USR1 and USR2 don't work on the JVM
      sigs << "USR2" if Sidekiq.pro? && !jruby?
      sigs.each do |sig|
        old_handler = Signal.trap(sig) do
          if old_handler.respond_to?(:call)
            begin
              old_handler.call
            rescue Exception => exc
              # signal handlers can't use Logger so puts only
              puts ["Error in #{sig} handler", exc].inspect
            end
          end
          self_write.puts(sig)
        end
      rescue ArgumentError
        puts "Signal #{sig} not supported"
      end

      logger.info "Running in #{RUBY_DESCRIPTION}"
      logger.info Sidekiq::LICENSE
      logger.info "Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org" unless defined?(::Sidekiq::Pro)

      # touch the connection pool so it is created before we
      # fire startup and start multithreading.
      info = @config.redis_info
      ver = info["redis_version"]
      raise "You are connecting to Redis v#{ver}, Sidekiq requires Redis v4.0.0 or greater" if ver < "4"

      maxmemory_policy = info["maxmemory_policy"]
      if maxmemory_policy != "noeviction"
        logger.warn <<~EOM


          WARNING: Your Redis instance will evict Sidekiq data under heavy load.
          The 'noeviction' maxmemory policy is recommended (current policy: '#{maxmemory_policy}').
          See: https://github.com/mperham/sidekiq/wiki/Using-Redis#memory

        EOM
      end

      # Since the user can pass us a connection pool explicitly in the initializer, we
      # need to verify the size is large enough or else Sidekiq's performance is dramatically slowed.
      cursize = @config.redis_pool.size
      needed = @config[:concurrency] + 2
      raise "Your pool of #{cursize} Redis connections is too small, please increase the size to at least #{needed}" if cursize < needed

      # cache process identity
      @config[:identity] = identity

      # Touch middleware so it isn't lazy loaded by multiple threads, #3043
      @config.server_middleware

      # Before this point, the process is initializing with just the main thread.
      # Starting here the process will now have multiple threads running.
      fire_event(:startup, reverse: false, reraise: true)

      logger.debug { "Client Middleware: #{@config.client_middleware.map(&:klass).join(", ")}" }
      logger.debug { "Server Middleware: #{@config.server_middleware.map(&:klass).join(", ")}" }

      launch(self_read)
    end

    def launch(self_read)
      if environment == "development" && $stdout.tty?
        logger.info "Starting processing, hit Ctrl-C to stop"
      end

      @launcher = Sidekiq::Launcher.new(@config)

      begin
        launcher.run

        while self_read.wait_readable
          signal = self_read.gets.strip
          handle_signal(signal)
        end
      rescue Interrupt
        logger.info "Shutting down"
        launcher.stop
        logger.info "Bye!"

        # Explicitly exit so busy Processor threads won't block process shutdown.
        #
        # NB: slow at_exit handlers will prevent a timely exit if they take
        # a while to run. If Sidekiq is getting here but the process isn't exiting,
        # use the TTIN signal to determine where things are stuck.
        exit(0)
      end
    end

    def self.w
      "\e[37m"
    end

    def self.r
      "\e[31m"
    end

    def self.b
      "\e[30m"
    end

    def self.reset
      "\e[0m"
    end

    def self.banner
      %{
      #{w}         m,
      #{w}         `$b
      #{w}    .ss,  $$:         .,d$
      #{w}    `$$P,d$P'    .,md$P"'
      #{w}     ,$$$$$b#{b}/#{w}md$$$P^'
      #{w}   .d$$$$$$#{b}/#{w}$$$P'
      #{w}   $$^' `"#{b}/#{w}$$$'       #{r}____  _     _      _    _
      #{w}   $:     ,$$:      #{r} / ___|(_) __| | ___| | _(_) __ _
      #{w}   `b     :$$       #{r} \\___ \\| |/ _` |/ _ \\ |/ / |/ _` |
      #{w}          $$:        #{r} ___) | | (_| |  __/   <| | (_| |
      #{w}          $$         #{r}|____/|_|\\__,_|\\___|_|\\_\\_|\\__, |
      #{w}        .d$$          #{r}                             |_|
      #{reset}}
    end

    SIGNAL_HANDLERS = {
      # Ctrl-C in terminal
      "INT" => ->(cli) { raise Interrupt },
      # TERM is the signal that Sidekiq must exit.
      # Heroku sends TERM and then waits 30 seconds for process to exit.
      "TERM" => ->(cli) { raise Interrupt },
      "TSTP" => ->(cli) {
        cli.logger.info "Received TSTP, no longer accepting new work"
        cli.launcher.quiet
      },
      "TTIN" => ->(cli) {
        Thread.list.each do |thread|
          cli.logger.warn "Thread TID-#{(thread.object_id ^ ::Process.pid).to_s(36)} #{thread.name}"
          if thread.backtrace
            cli.logger.warn thread.backtrace.join("\n")
          else
            cli.logger.warn "<no backtrace available>"
          end
        end
      }
    }
    UNHANDLED_SIGNAL_HANDLER = ->(cli) { cli.logger.info "No signal handler registered, ignoring" }
    SIGNAL_HANDLERS.default = UNHANDLED_SIGNAL_HANDLER

    def handle_signal(sig)
      logger.debug "Got #{sig} signal"
      SIGNAL_HANDLERS[sig].call(self)
    end

    private

    def print_banner
      puts "\e[31m"
      puts Sidekiq::CLI.banner
      puts "\e[0m"
    end

    def set_environment(cli_env)
      # See #984 for discussion.
      # APP_ENV is now the preferred ENV term since it is not tech-specific.
      # Both Sinatra 2.0+ and Sidekiq support this term.
      # RAILS_ENV and RACK_ENV are there for legacy support.
      @environment = cli_env || ENV["APP_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
      config[:environment] = @environment
    end

    def symbolize_keys_deep!(hash)
      hash.keys.each do |k|
        symkey = k.respond_to?(:to_sym) ? k.to_sym : k
        hash[symkey] = hash.delete k
        symbolize_keys_deep! hash[symkey] if hash[symkey].is_a? Hash
      end
    end

    alias_method :die, :exit
    alias_method :☠, :exit

    def setup_options(args)
      # parse CLI options
      opts = parse_options(args)

      set_environment opts[:environment]

      # check config file presence
      if opts[:config_file]
        unless File.exist?(opts[:config_file])
          raise ArgumentError, "No such file #{opts[:config_file]}"
        end
      else
        config_dir = if File.directory?(opts[:require].to_s)
          File.join(opts[:require], "config")
        else
          File.join(@config[:require], "config")
        end

        %w[sidekiq.yml sidekiq.yml.erb].each do |config_file|
          path = File.join(config_dir, config_file)
          opts[:config_file] ||= path if File.exist?(path)
        end
      end

      # parse config file options
      opts = parse_config(opts[:config_file]).merge(opts) if opts[:config_file]

      # set defaults
      opts[:queues] = ["default"] if opts[:queues].nil?
      opts[:concurrency] = Integer(ENV["RAILS_MAX_THREADS"]) if opts[:concurrency].nil? && ENV["RAILS_MAX_THREADS"]

      # merge with defaults
      @config.merge!(opts)
    end

    def boot_application
      ENV["RACK_ENV"] = ENV["RAILS_ENV"] = environment

      if File.directory?(@config[:require])
        require "rails"
        if ::Rails::VERSION::MAJOR < 5
          raise "Sidekiq no longer supports this version of Rails"
        else
          require "sidekiq/rails"
          require File.expand_path("#{@config[:require]}/config/environment.rb")
        end
        @config[:tag] ||= default_tag
      else
        require @config[:require]
      end
    end

    def default_tag
      dir = ::Rails.root
      name = File.basename(dir)
      prevdir = File.dirname(dir) # Capistrano release directory?
      if name.to_i != 0 && prevdir
        if File.basename(prevdir) == "releases"
          return File.basename(File.dirname(prevdir))
        end
      end
      name
    end

    def validate!
      if !File.exist?(@config[:require]) ||
          (File.directory?(@config[:require]) && !File.exist?("#{@config[:require]}/config/application.rb"))
        logger.info "=================================================================="
        logger.info "  Please point Sidekiq to a Rails application or a Ruby file  "
        logger.info "  to load your job classes with -r [DIR|FILE]."
        logger.info "=================================================================="
        logger.info @parser
        die(1)
      end

      [:concurrency, :timeout].each do |opt|
        raise ArgumentError, "#{opt}: #{@config[opt]} is not a valid value" if @config[opt].to_i <= 0
      end
    end

    def parse_options(argv)
      opts = {}
      @parser = option_parser(opts)
      @parser.parse!(argv)
      opts
    end

    def option_parser(opts)
      parser = OptionParser.new { |o|
        o.on "-c", "--concurrency INT", "processor threads to use" do |arg|
          opts[:concurrency] = Integer(arg)
        end

        o.on "-d", "--daemon", "Daemonize process" do |arg|
          puts "ERROR: Daemonization mode was removed in Sidekiq 6.0, please use a proper process supervisor to start and manage your services"
        end

        o.on "-e", "--environment ENV", "Application environment" do |arg|
          opts[:environment] = arg
        end

        o.on "-g", "--tag TAG", "Process tag for procline" do |arg|
          opts[:tag] = arg
        end

        o.on "-q", "--queue QUEUE[,WEIGHT]", "Queues to process with optional weights" do |arg|
          queue, weight = arg.split(",")
          parse_queue opts, queue, weight
        end

        o.on "-r", "--require [PATH|DIR]", "Location of Rails application with jobs or file to require" do |arg|
          opts[:require] = arg
        end

        o.on "-t", "--timeout NUM", "Shutdown timeout" do |arg|
          opts[:timeout] = Integer(arg)
        end

        o.on "-v", "--verbose", "Print more verbose output" do |arg|
          opts[:verbose] = arg
        end

        o.on "-C", "--config PATH", "path to YAML config file" do |arg|
          opts[:config_file] = arg
        end

        o.on "-L", "--logfile PATH", "path to writable logfile" do |arg|
          puts "ERROR: Logfile redirection was removed in Sidekiq 6.0, Sidekiq will only log to STDOUT"
        end

        o.on "-P", "--pidfile PATH", "path to pidfile" do |arg|
          puts "ERROR: PID file creation was removed in Sidekiq 6.0, please use a proper process supervisor to start and manage your services"
        end

        o.on "-V", "--version", "Print version and exit" do |arg|
          puts "Sidekiq #{Sidekiq::VERSION}"
          die(0)
        end
      }

      parser.banner = "sidekiq [options]"
      parser.on_tail "-h", "--help", "Show help" do
        logger.info parser
        die 1
      end

      parser
    end

    def initialize_logger
      @config.logger.level = ::Logger::DEBUG if @config[:verbose]
    end

    def parse_config(path)
      erb = ERB.new(File.read(path))
      erb.filename = File.expand_path(path)
      opts = load_yaml(erb.result) || {}

      if opts.respond_to? :deep_symbolize_keys!
        opts.deep_symbolize_keys!
      else
        symbolize_keys_deep!(opts)
      end

      opts = opts.merge(opts.delete(environment.to_sym) || {})
      opts.delete(:strict)

      parse_queues(opts, opts.delete(:queues) || [])

      opts
    end

    def load_yaml(src)
      if Psych::VERSION > "4.0"
        YAML.safe_load(src, permitted_classes: [Symbol], aliases: true)
      else
        YAML.load(src)
      end
    end

    def parse_queues(opts, queues_and_weights)
      queues_and_weights.each { |queue_and_weight| parse_queue(opts, *queue_and_weight) }
    end

    def parse_queue(opts, queue, weight = nil)
      opts[:queues] ||= []
      opts[:strict] = true if opts[:strict].nil?
      raise ArgumentError, "queues: #{queue} cannot be defined twice" if opts[:queues].include?(queue)
      [weight.to_i, 1].max.times { opts[:queues] << queue.to_s }
      opts[:strict] = false if weight.to_i > 0
    end

    def rails_app?
      defined?(::Rails) && ::Rails.respond_to?(:application)
    end
  end
end

require "sidekiq/systemd"
require "sidekiq/metrics/tracking" if ENV["SIDEKIQ_METRICS_BETA"]
