# encoding: UTF-8

require 'thor'
require 'rainbow'

module Rpush
  class CLI < Thor
    def self.detect_rails?
      ['bin/rails', 'script/rails'].any? { |path| File.exist?(path) }
    end

    def self.default_config_path
      detect_rails? ? 'config/initializers/rpush.rb' : 'config/rpush.rb'
    end

    class_option :config, type: :string, aliases: '-c', default: default_config_path
    class_option 'rails-env', type: :string, aliases: '-e', default: ENV.fetch('RAILS_ENV', 'development')

    option :foreground, type: :boolean, aliases: '-f', default: false
    option 'pid-file', type: :string, aliases: '-p'
    desc 'start', 'Start Rpush'
    def start
      config_setup

      require 'rpush/daemon'
      Rpush::Daemon.start
    end

    desc 'stop', 'Stop Rpush'
    option 'pid-file', type: :string, aliases: '-p'
    def stop
      config_setup
      pid = rpush_process_pid
      return unless pid

      STDOUT.write "* Stopping Rpush (pid #{pid})... "
      STDOUT.flush
      Process.kill('TERM', pid)

      loop do
        begin
          Process.getpgid(pid)
          sleep 0.05
        rescue Errno::ESRCH
          break
        end
      end

      puts Rainbow('✔').green
    end

    desc 'init', 'Initialize Rpush into the current directory'
    option 'active-record', type: :boolean, desc: 'Install ActiveRecord migrations'
    def init
      underscore_option_names
      require 'rails/generators'

      puts "* " + Rainbow('Installing config...').green
      $RPUSH_CONFIG_PATH = default_config_path # rubocop:disable Style/GlobalVars
      Rails::Generators.invoke('rpush_config')

      install_migrations = options['active_record']

      unless options.key?('active_record')
        answer = ask("\n* #{Rainbow('Install ActiveRecord migrations?').green}", limited_to: %w[y n])
        install_migrations = answer == 'y'
      end

      Rails::Generators.invoke('rpush_migration', ['--force']) if install_migrations

      puts "\n* #{Rainbow('Next steps:').green}"
      puts "  - Run 'bundle exec rake db:migrate'." if install_migrations
      puts "  - Review and update your configuration in #{default_config_path}."
      puts "  - Create your first app, see https://github.com/rpush/rpush for examples."
      puts "  - Run 'rpush help' for commands and options."
    end

    desc 'push', 'Deliver all pending notifications and then exit'
    def push
      config_setup
      Rpush.config.foreground = true

      Rpush.push
    end

    desc 'status', 'Show the internal status of the running Rpush instance.'
    def status
      config_setup

      require 'rpush/daemon'
      rpc = Rpush::Daemon::Rpc::Client.new(rpush_process_pid)
      status = rpc.status
      rpc.close
      puts humanize_json(status)
    end

    desc 'version', 'Print Rpush version'
    def version
      puts Rpush::VERSION
    end

    private

    def config_setup
      underscore_option_names
      configure_rpush
    end

    def configure_rpush
      load_rails_environment || load_standalone
    end

    def load_rails_environment
      if detect_rails? && options['rails_env']
        STDOUT.write "* Booting Rails '#{options[:rails_env]}' environment... "
        STDOUT.flush
        ENV['RAILS_ENV'] = options['rails_env']
        load 'config/environment.rb'
        Rpush.config.update(options)
        puts Rainbow('✔').green

        return true
      end

      false
    end

    def load_standalone
      if !File.exist?(options[:config])
        STDERR.puts(Rainbow('ERROR: ').red + "#{options[:config]} does not exist. Please run 'rpush init' to generate it or specify the --config option.")
        exit 1
      else
        load options[:config]
        Rpush.config.update(options)
      end
    end

    def detect_rails?
      self.class.detect_rails?
    end

    def default_config_path
      self.class.default_config_path
    end

    def underscore_option_names
      # Underscore option names so that they map directly to Configuration options.
      new_options = options.dup

      options.each do |k, v|
        new_k = k.to_s.tr('-', '_')

        if k != new_k
          new_options.delete(k)
          new_options[new_k] = v
        end
      end

      new_options.freeze
      self.options = new_options
    end

    def rpush_process_pid
      if Rpush.config.pid_file.blank?
        STDERR.puts(Rainbow('ERROR: ').red + 'config.pid_file is not set.')
        exit 1
      end

      unless File.exist?(Rpush.config.pid_file)
        STDERR.puts("* Rpush isn't running? #{Rpush.config.pid_file} does not exist.")
        exit 1
      end

      File.read(Rpush.config.pid_file).strip.to_i
    end

    def humanize_json(node, str = '', depth = 0) # rubocop:disable Metrics/PerceivedComplexity
      if node.is_a?(Hash)
        node = node.sort_by { |_, v| [Array, Hash].include?(v.class) ? 1 : 0 }
        node.each do |k, v|
          if [Array, Hash].include?(v.class)
            str << "\n#{'  ' * depth}#{k}:\n"
            humanize_json(v, str, depth + 1)
          else
            str << "#{'  ' * depth}#{k}: #{v}\n"
          end
        end
      elsif node.is_a?(Array)
        node.each do |v|
          str << "\n" if v.is_a?(Hash)
          humanize_json(v, str, depth)
        end
      else
        str << "#{'  ' * depth}#{node}\n"
      end

      str
    end
  end
end
