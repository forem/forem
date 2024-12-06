require 'honeybadger/plugin'

module Honeybadger
  Plugin.register do
    requirement { defined?(::Delayed::Plugin) }
    requirement { defined?(::Delayed::Worker.plugins) }
    requirement do
      if delayed_job_honeybadger = defined?(::Delayed::Plugins::Honeybadger)
        logger.warn("Support for Delayed Job has been moved " \
                    "to the honeybadger gem. Please remove " \
                    "delayed_job_honeybadger from your " \
                    "Gemfile.")
      end
      !delayed_job_honeybadger
    end

    execution do
      require 'honeybadger/plugins/delayed_job/plugin'
      ::Delayed::Worker.plugins << Plugins::DelayedJob::Plugin
    end
  end
end
