require 'delayed_job'
require 'honeybadger/ruby'

module Honeybadger
  module Plugins
    module DelayedJob
      class Plugin < ::Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.around(:invoke_job) do |job, &block|
            begin

              begin
                if job.payload_object.class.name == 'ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper'
                  #buildin support for Rails 4.2 ActiveJob
                  component = job.payload_object.job_data['job_class']
                  action = 'perform'
                else
                  #buildin support for Delayed::PerformableMethod
                  component = job.payload_object.object.is_a?(Class) ? job.payload_object.object.name : job.payload_object.object.class.name
                  action    = job.payload_object.method_name.to_s
                end
              rescue #fallback to support all other classes
                component = job.payload_object.class.name
                action    = 'perform'
              end

              ::Honeybadger.context(
                :component     => component,
                :action        => action,
                :job_id        => job.id,
                :handler       => job.handler,
                :last_error    => job.last_error,
                :attempts      => job.attempts,
                :queue         => job.queue
              )

              block.call(job)
            rescue Exception => error
              ::Honeybadger.notify(
                :component     => component,
                :action        => action,
                :error_class   => error.class.name,
                :error_message => "#{ error.class.name }: #{ error.message }",
                :backtrace     => error.backtrace,
                :exception     => error
              ) if job.attempts.to_i >= ::Honeybadger.config[:'delayed_job.attempt_threshold'].to_i
              raise error
            ensure
              ::Honeybadger.clear!
            end
          end
        end
      end
    end
  end
end
