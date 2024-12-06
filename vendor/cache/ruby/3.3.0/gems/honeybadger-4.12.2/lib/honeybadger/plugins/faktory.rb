require 'honeybadger/plugin'
require 'honeybadger/ruby'

module Honeybadger
  module Plugins
    module Faktory
      class Middleware
        def call(worker, job)
          Honeybadger.clear!
          yield
        end
      end

      Plugin.register do
        requirement { defined?(::Faktory) }

        execution do
          ::Faktory.configure_worker do |faktory|
            faktory.worker_middleware do |chain|
              chain.prepend Middleware
            end
          end

          ::Faktory.configure_worker do |faktory|
            faktory.error_handlers << lambda do |ex, params|
              opts = {parameters: params}

              if job = params[:job]
                if (threshold = config[:'faktory.attempt_threshold'].to_i) > 0
                  # If job.failure is nil, it is the first attempt. The first
                  # retry has a job.failure.retry_count of 0, which would be
                  # the second attempt in our case.
                  retry_count = job.dig('failure', 'retry_count')
                  attempt = retry_count ? retry_count + 1 : 0

                  limit = [job['retry'].to_i, threshold].min

                  return if attempt < limit
                end

                opts[:component] = job['jobtype']
                opts[:action] = 'perform'
              end

              Honeybadger.notify(ex, opts)
            end
          end
        end
      end
    end
  end
end
