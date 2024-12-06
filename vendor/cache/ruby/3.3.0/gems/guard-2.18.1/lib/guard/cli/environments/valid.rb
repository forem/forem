require "guard/cli/environments/bundler"
require "guard/commander"
require "guard/guardfile/generator"

module Guard
  module Cli
    module Environments
      class Valid
        def initialize(options)
          @options = options
        end

        def start_guard
          # TODO: just to make sure tests are ok
          Bundler.new.verify unless @options[:no_bundler_warning]
          Guard.start(@options)
        rescue Dsl::Error,
               Guardfile::Evaluator::NoPluginsError,
               Guardfile::Evaluator::NoGuardfileError,
               Guardfile::Evaluator::NoCustomGuardfile => e
          # catch to throw message instead of call stack
          UI.error(e.message)
          abort
        end

        def initialize_guardfile(plugin_names = [])
          bare = @options[:bare]

          Guard.init(@options)
          session = Guard.state.session

          generator = Guardfile::Generator.new
          begin
            Guardfile::Evaluator.new(session.evaluator_options).evaluate
          rescue Guardfile::Evaluator::NoGuardfileError
            generator.create_guardfile
          rescue Guard::Guardfile::Evaluator::NoPluginsError
            # Do nothing - just the error
          end

          return 0 if bare # 0 - exit code

          # Evaluate because it might have existed and creating was skipped
          begin
            Guardfile::Evaluator.new(session.evaluator_options).evaluate
          rescue Guard::Guardfile::Evaluator::NoPluginsError
          end

          begin
            if plugin_names.empty?
              generator.initialize_all_templates
            else
              plugin_names.each do |plugin_name|
                generator.initialize_template(plugin_name)
              end
            end
          rescue Guardfile::Generator::Error => e
            UI.error(e.message)
            return 1
          end

          # TODO: capture exceptions to show msg and return exit code on
          # failures
          0 # exit code
        end
      end
    end
  end
end
