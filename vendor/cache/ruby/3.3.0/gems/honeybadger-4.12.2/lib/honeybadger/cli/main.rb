require 'honeybadger/cli/deploy'
require 'honeybadger/cli/exec'
require 'honeybadger/cli/heroku'
require 'honeybadger/cli/install'
require 'honeybadger/cli/notify'
require 'honeybadger/cli/test'
require 'honeybadger/config'
require 'honeybadger/config/defaults'
require 'honeybadger/ruby'
require 'honeybadger/util/http'
require 'honeybadger/version'
require 'logger'

module Honeybadger
  module CLI
    BLANK = /\A\s*\z/

    NOTIFIER = {
      name: 'honeybadger-ruby (cli)'.freeze,
      url: 'https://github.com/honeybadger-io/honeybadger-ruby'.freeze,
      version: VERSION,
      language: nil
    }.freeze

    class Main < Thor
      def self.project_options
        option :api_key,         required: false, aliases: :'-k', type: :string, desc: 'Api key of your Honeybadger application'
        option :environment,     required: false, aliases: [:'-e', :'-env'], type: :string, desc: 'Environment this command is being executed in (i.e. "production", "staging")'
        option :skip_rails_load, required: false, type: :boolean, desc: 'Flag to skip rails initialization'
      end

      def help(*args, &block)
        if args.size == 0
          say(<<-WELCOME)
⚡  Honeybadger v#{VERSION}

Honeybadger is your favorite error tracker for Ruby. When your app raises an
exception we notify you with all the context you need to fix it.

The Honeybadger CLI provides tools for interacting with Honeybadger via the
command line.

If you need support, please drop us a line: support@honeybadger.io

WELCOME
        end
        super
      end

      desc 'install API_KEY', 'Install Honeybadger into a new project'
      def install(api_key)
        Install.new(options, api_key).run
      rescue => e
        log_error(e)
        exit(1)
      end

      desc 'test', 'Send a test notification from Honeybadger'
      option :dry_run, type: :boolean, aliases: :'-d', default: false, desc: 'Skip sending data to Honeybadger'
      option :file,    type: :string,  aliases: :'-f', default: nil, desc: 'Write the output to FILE'
      def test
        Test.new(options).run
      rescue => e
        log_error(e)
        exit(1)
      end

      desc 'deploy', 'Notify Honeybadger of deployment'
      project_options
      option :repository, required: true, type: :string, aliases: :'-r', desc: 'The address of your repository'
      option :revision,   required: true, type: :string, aliases: :'-s', desc: 'The revision/sha that is being deployed'
      option :user,       required: true, type: :string, aliases: :'-u', default: ENV['USER'] || ENV['USERNAME'], desc: 'The local user who is deploying'
      def deploy
        config = build_config(options)

        if config.get(:api_key).to_s =~ BLANK
          say("No value provided for required options '--api-key'")
          exit(1)
        end

        Deploy.new(options, [], config).run
      rescue => e
        log_error(e)
        exit(1)
      end

      desc 'notify', 'Notify Honeybadger of an error'
      project_options
      option :class,       required: true, type: :string, aliases: :'-c', default: 'CLI Notification', desc: 'The class name of the error. (Default: CLI Notification)'
      option :message,     required: true, type: :string, aliases: :'-m', desc: 'The error message.'
      option :action,      required: false, type: :string, aliases: :'-a', desc: 'The action.'
      option :component,   required: false, type: :string, aliases: :'-C', desc: 'The component.'
      option :fingerprint, required: false, type: :string, aliases: :'-f', desc: 'The fingerprint.'
      option :tags,        required: false, type: :string, aliases: :'-t', desc: 'The tags.'
      option :url,         required: false, type: :string, aliases: :'-u', desc: 'The URL.'
      def notify
        config = build_config(options)

        if config.get(:api_key).to_s =~ BLANK
          say("No value provided for required options '--api-key'")
          exit(1)
        end

        Notify.new(options, [], config).run
      rescue => e
        log_error(e)
        exit(1)
      end

      desc 'exec', 'Execute a command. If the exit status is not 0, report the result to Honeybadger'
      project_options
      option :quiet, required: false, type: :boolean, aliases: :'-q', default: false, desc: 'Suppress all output unless notification fails.'
      def exec(*args)
        if args.size == 0
          say("honeybadger: exec needs a command to run", :red)
          exit(1)
        end

        config = build_config(options)

        if config.get(:api_key).to_s =~ BLANK
          say("No value provided for required options '--api-key'", :red)
          exit(1)
        end

        Exec.new(options, args, config).run
      rescue => e
        log_error(e)
        exit(1)
      end

      desc 'heroku SUBCOMMAND ...ARGS', 'Manage Honeybadger on Heroku'
      subcommand 'heroku', Heroku

      private

      def fetch_value(options, key)
        options[key] == key ? nil : options[key]
      end

      def build_config(options)
        load_env(options)

        config = Honeybadger.config
        config.set(:report_data, true)
        config.set(:api_key, fetch_value(options, 'api_key')) if options.has_key?('api_key')
        config.set(:env, fetch_value(options, 'environment')) if options.has_key?('environment')

        config
      end

      def load_env(options)
        # Initialize Rails when running from Rails root.
        environment_rb = File.join(Dir.pwd, 'config', 'environment.rb')
        if File.exist?(environment_rb)
          load_rails_env_if_allowed(environment_rb, options)
        end
        # Ensure config is loaded (will be skipped if initialized by Rails).
        Honeybadger.config.load!
      end

      def load_rails_env_if_allowed(environment_rb, options)
        # Skip Rails initialization according to option flag
        if options.has_key?('skip_rails_load') && fetch_value(options, 'skip_rails_load')
          say("Skipping Rails initialization.")
        else
          load_rails_env(environment_rb)
        end
      end

      def load_rails_env(environment_rb)
        begin
          require 'rails'
        rescue LoadError
          # No Rails, so skip loading Rails environment.
          return
        end
        require environment_rb
      end

      def log_error(e)
        case e
        when *Util::HTTP::ERRORS
          say(<<-MSG, :red)
!! --- Failed to notify Honeybadger ------------------------------------------- !!

# What happened?

  We encountered an HTTP error while contacting our service. Issues like this are
  usually temporary.

# Error details

  #{e.class}: #{e.message}\n    at #{e.backtrace && e.backtrace.first}

# What can I do?

  - Retry the command.
  - Make sure you can connect to api.honeybadger.io (`curl https://api.honeybadger.io/v1/notices`).
  - If you continue to see this message, email us at support@honeybadger.io
    (don't forget to attach this output!)

!! --- End -------------------------------------------------------------------- !!
MSG
        else
          say(<<-MSG, :red)
!! --- Honeybadger command failed --------------------------------------------- !!

# What did you try to do?

  You tried to execute the following command:
  `honeybadger #{ARGV.join(' ')}`

# What actually happend?

  We encountered a Ruby exception and were forced to cancel your request.

# Error details

  #{e.class}: #{e.message}
    #{e.backtrace && e.backtrace.join("\n    ")}

# What can I do?

  - If you're calling the `install` or `test` command in a Rails app, make sure
    you can boot the Rails console: `bundle exec rails console`.
  - Retry the command.
  - If you continue to see this message, email us at support@honeybadger.io
    (don't forget to attach this output!)

!! --- End -------------------------------------------------------------------- !!
MSG
        end
      end
    end
  end
end
