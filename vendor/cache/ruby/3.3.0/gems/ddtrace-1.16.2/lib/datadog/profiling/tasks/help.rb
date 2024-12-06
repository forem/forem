module Datadog
  module Profiling
    module Tasks
      # Prints help message for usage of `ddtrace`
      class Help
        def run
          puts %(
  Usage: ddtracerb [command] [arguments]
    exec [command]: Executes command with tracing & profiling preloaded.
    help:           Prints this help message.
          )
        end
      end
    end
  end
end
