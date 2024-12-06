require 'capistrano'

module Honeybadger
  module Capistrano
    def self.load_into(configuration)
      configuration.load do
        after 'deploy',            'honeybadger:deploy'
        after 'deploy:migrations', 'honeybadger:deploy'

        namespace :honeybadger do
          desc <<-DESC
            Notify Honeybadger of the deployment by running the notification on the REMOTE machine.
              - Run remotely so we use remote API keys, environment, etc.
          DESC
          task :deploy, :except => { :no_release => true } do
            revision = capture("#{try_sudo} cat #{current_path}/REVISION", :except => { :no_release => true }).chomp
            rails_env = fetch(:rails_env, 'production')
            honeybadger_env = fetch(:honeybadger_env, fetch(:rails_env, 'production'))
            local_user = fetch(:honeybadger_user, ENV['USER'] || ENV['USERNAME'])
            executable = fetch(:honeybadger, "#{fetch(:bundle_cmd, 'bundle')} exec honeybadger")
            async_notify = fetch(:honeybadger_async_notify, false)
            directory = fetch(:honeybadger_deploy_dir, configuration.current_release)
            notify_options = "cd #{directory};"
            notify_options << " RAILS_ENV=#{rails_env}"
            notify_options << ' nohup' if async_notify
            notify_options << " #{executable} deploy --environment=#{honeybadger_env} --revision=#{revision} --repository=#{repository} --user=#{local_user}"
            notify_options << ' --dry-run' if dry_run
            notify_options << " --api-key=#{ENV['API_KEY']}" if ENV['API_KEY']
            notify_options << ' >> /dev/null 2>&1 &' if async_notify
            logger.info "Notifying Honeybadger of Deploy (#{notify_options})"
            if configuration.dry_run
              logger.info 'DRY RUN: Notification not actually run.'
            else
              result = ''
              run("#{ notify_options }; true", :once => true, :pty => false) { |ch, stream, data| result << data }
            end
            logger.info 'Honeybadger Notification Complete.'
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Honeybadger::Capistrano.load_into(Capistrano::Configuration.instance)
end
