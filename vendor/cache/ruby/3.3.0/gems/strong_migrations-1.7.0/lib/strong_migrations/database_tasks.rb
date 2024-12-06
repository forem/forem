module StrongMigrations
  module DatabaseTasks
    # Active Record 7 adds version argument
    def migrate(*args)
      super
    rescue => e
      if e.cause.is_a?(StrongMigrations::Error)
        # strip cause and clean backtrace
        def e.cause
          nil
        end

        def e.message
          super.sub("\n\n\n", "\n\n") + "\n"
        end

        unless Rake.application.options.trace
          def e.backtrace
            bc = ActiveSupport::BacktraceCleaner.new
            bc.add_silencer { |line| line =~ /strong_migrations/ }
            bc.clean(super)
          end
        end
      end

      raise e
    end
  end
end
