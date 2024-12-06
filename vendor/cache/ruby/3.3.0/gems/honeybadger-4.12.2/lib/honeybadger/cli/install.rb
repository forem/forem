require 'forwardable'
require 'honeybadger/cli/main'
require 'honeybadger/cli/test'
require 'pathname'

module Honeybadger
  module CLI
    class Install
      extend Forwardable

      def initialize(options, api_key)
        @options = options
        @api_key = api_key
        @shell = ::Thor::Base.shell.new
      end

      def run
        say("Installing Honeybadger #{VERSION}")

        begin
          require File.join(Dir.pwd, 'config', 'application.rb')
          raise LoadError unless defined?(::Rails.application)
          root = Rails.root
          config_root = root.join('config')
        rescue LoadError
          root = config_root = Pathname.new(Dir.pwd)
        end

        config_path = config_root.join('honeybadger.yml')

        if config_path.exist?
          say("You're already on Honeybadger, so you're all set.", :yellow)
        else
          say("Writing configuration to: #{config_path}", :yellow)

          path = config_path

          if path.exist?
            say("The configuration file #{config_path} already exists.", :red)
            exit(1)
          elsif !path.dirname.writable?
            say("The configuration path #{config_path.dirname} is not writable.", :red)
            exit(1)
          end

          default_env = defined?(::Rails.application) ? "Rails.env" : "ENV['RUBY_ENV'] || ENV['RACK_ENV']"
          default_root = defined?(::Rails.application) ? "Rails.root.to_s" : "Dir.pwd"
          File.open(path, 'w+') do |file|
            file.write(<<-CONFIG)
---
# For more options, see https://docs.honeybadger.io/lib/ruby/gem-reference/configuration

api_key: '#{api_key}'

# The environment your app is running in.
env: "<%= #{default_env} %>"

# The absolute path to your project folder.
root: "<%= #{default_root} %>"

# Honeybadger won't report errors in these environments.
development_environments:
- test
- development
- cucumber

# By default, Honeybadger won't report errors in the development_environments.
# You can override this by explicitly setting report_data to true or false.
# report_data: true

# The current Git revision of your project. Defaults to the last commit hash.
# revision: null

# Enable verbose debug logging (useful for troubleshooting).
debug: false
CONFIG
          end
        end

        if (capfile = root.join('Capfile')).exist?
          if capfile.read.match(/honeybadger/)
            say("Detected Honeybadger in Capfile; skipping Capistrano installation.", :yellow)
          else
            say("Appending Capistrano tasks to: #{capfile}", :yellow)
            File.open(capfile, 'a') do |f|
              f.puts("\nrequire 'capistrano/honeybadger'")
            end
          end
        end

        Test.new({install: true}.freeze).run
      end

      private

      attr_reader :options, :api_key

      def_delegator :@shell, :say
    end
  end
end
