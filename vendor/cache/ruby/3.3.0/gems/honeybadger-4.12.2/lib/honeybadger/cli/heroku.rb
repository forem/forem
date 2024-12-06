module Honeybadger
  module CLI
    class Heroku < Thor
      class_option :app, aliases: :'-a', type: :string, default: nil, desc: 'Specify optional Heroku APP'

      desc 'install_deploy_notification', 'Install Heroku deploy notifications addon'
      option :api_key, aliases: :'-k', type: :string, desc: 'Api key of your Honeybadger application'
      option :environment, aliases: :'-e', type: :string, desc: 'Environment of your Heroku application (i.e. "production", "staging")'
      def install_deploy_notification
        app       = options.has_key?('app') ? options['app'] : detect_heroku_app(false)
        rails_env = options['environment'] || heroku_var('RAILS_ENV', app)
        api_key   = options['api_key'] || heroku_var('HONEYBADGER_API_KEY', app)

        unless api_key =~ /\S/
          say("Unable to detect your API key from Heroku.", :red)
          say('Have you configured multiple Heroku apps? Try using --app APP', :red) unless app
          exit(1)
        end

        unless rails_env =~ /\S/
          say("Unable to detect your environment from Heroku. Use --environment ENVIRONMENT.", :red)
          say('Have you configured multiple Heroku apps? Try using --app APP', :red) unless app
          exit(1)
        end

        cmd = %Q(heroku addons:create deployhooks:http --url="https://api.honeybadger.io/v1/deploys?deploy[environment]=#{rails_env}&deploy[local_username]={{user}}&deploy[revision]={{head}}&api_key=#{api_key}"#{app ? " --app #{app}" : ''})

        say("Running: `#{cmd}`")
        say(run(cmd))
      end

      desc 'install API_KEY', 'Install Honeybadger on Heroku using API_KEY'
      def install(api_key)
        say("Installing Honeybadger #{VERSION} for Heroku")

        app = options[:app] || detect_heroku_app(false)
        say("Adding config HONEYBADGER_API_KEY=#{api_key} to Heroku.", :magenta)
        unless write_heroku_env({'HONEYBADGER_API_KEY' => api_key}, app)
          say('Unable to update heroku config. You may need to specify an app name with --app APP', :red)
          exit(1)
        end

        if env = heroku_var('RAILS_ENV', app, heroku_var('RACK_ENV', app))
          say('Installing deploy notification addon', :magenta)
          invoke :install_deploy_notification, [], { app: app, api_key: api_key, environment: env }
        else
          say('Skipping deploy notification installation: we were unable to determine the environment name from your Heroku app.', :yellow)
          say("To install manually, try `honeybadger heroku install_deploy_notification#{app ? " -a #{app}" : ""} -k #{api_key} --environment ENVIRONMENT`", :yellow)
        end

        say("Installation complete. Happy 'badgering!", :green)
      end

      private

      # Detects the Heroku app name from GIT.
      #
      # @param [Boolean] prompt_on_default If a single remote is discoverd,
      #   should we prompt the user before returning it?
      #
      # Returns the String app name if detected, otherwise nil.
      def detect_heroku_app(prompt_on_default = true)
        apps, git_config = {}, File.join(Dir.pwd, '.git', 'config')
        if File.exist?(git_config)
          require 'inifile'
          ini = IniFile.load(git_config)
          ini.each_section do |section|
            if match = section.match(/remote \"(?<remote>.+)\"/)
              url = ini[section]['url']
              if url_match = url.match(/heroku\.com:(?<app>.+)\.git$/)
                apps[match[:remote]] = url_match[:app]
              end
            end
          end

          if apps.size == 1
            if !prompt_on_default
              apps.values.first
            else
              say "We detected a Heroku app named #{apps.values.first}. Do you want to load the config? (y/yes or n/no)"
              if STDIN.gets.chomp =~ /(y|yes)/i
                apps.values.first
              end
            end
          elsif apps.size > 1
            say "We detected the following Heroku apps:"
            apps.each_with_index {|a,i| say "\s\s#{i+1}. #{a[1]}" }
            say "\s\s#{apps.size+1}. Use default"
            say "Please select an option (1-#{apps.size+1}):"
            apps.values[STDIN.gets.chomp.to_i-1]
          end
        end
      end

      def run(cmd)
        Bundler.with_unbundled_env { `#{cmd}` }
      end

      def heroku_var(var, app_name, default = nil)
        app = app_name ? "--app #{app_name}" : ''
        result = run("heroku config:get #{var} #{app} 2> /dev/null").strip
        result.split.find(lambda { default }) {|x| x =~ /\S/ }
      end

      def read_heroku_env(app = nil)
        cmd = ['heroku config']
        cmd << "--app #{app}" if app
        output = run(cmd.join("\s"))
        return false unless $?.to_i == 0
        Hash[output.scan(/(HONEYBADGER_[^:]+):\s*(\S.*)\s*$/)]
      end

      def set_env_from_heroku(app = nil)
        return false unless env = read_heroku_env(app)
        env.each_pair do |k,v|
          ENV[k] ||= v
        end
      end

      def write_heroku_env(env, app = nil)
        cmd = ["heroku config:set"]
        Hash(env).each_pair {|k,v| cmd << "#{k}=#{v}" }
        cmd << "--app #{app}" if app
        run(cmd.join("\s"))
        $?.to_i == 0
      end
    end
  end
end
