require 'honeybadger/plugin'
require 'honeybadger/ruby'

module Honeybadger
  module Plugins
    module Sidekiq
      class Middleware
        def call(_worker, _msg, _queue)
          Honeybadger.clear!
          yield
        end
      end

      Plugin.register do
        requirement { defined?(::Sidekiq) }

        execution do
          ::Sidekiq.configure_server do |sidekiq|
            sidekiq.server_middleware do |chain|
              chain.prepend Middleware
            end
          end

          if defined?(::Sidekiq::VERSION) && ::Sidekiq::VERSION > '3'
            ::Sidekiq.configure_server do |sidekiq|
              sidekiq.error_handlers << lambda { |ex, params|
                job = params[:job] || params
                job_retry = job['retry'.freeze]

                if (threshold = config[:'sidekiq.attempt_threshold'].to_i) > 0 && job_retry
                  # We calculate the job attempts to determine the need to
                  # skip. Sidekiq's first job execution will have nil for the
                  # 'retry_count' job key. The first retry will have 0 set for
                  # the 'retry_count' key, incrementing on each execution
                  # afterwards.
                  retry_count = job['retry_count'.freeze]
                  attempt = retry_count ? retry_count + 1 : 0

                  # Ensure we account for modified max_retries setting
                  default_max_retry_attempts = defined?(::Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS) ? ::Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS : 25
                  retry_limit = job_retry == true ? (sidekiq.options[:max_retries] || default_max_retry_attempts) : job_retry.to_i

                  limit = [retry_limit, threshold].min

                  return if attempt < limit
                end

                opts = { parameters: params }
                if config[:'sidekiq.use_component']
                  opts[:component] = job['wrapped'.freeze] || job['class'.freeze]
                  opts[:action] = 'perform' if opts[:component]
                end

                Honeybadger.notify(ex, opts)
              }
            end
          end
        end
      end
    end
  end
end
