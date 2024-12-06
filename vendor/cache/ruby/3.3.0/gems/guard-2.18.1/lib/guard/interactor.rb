require "forwardable"

module Guard
  class Interactor
    # Initializes the interactor. This configures
    # Pry and creates some custom commands and aliases
    # for Guard.
    #
    def initialize(no_interaction = false)
      @interactive = !no_interaction && self.class.enabled?

      # TODO: only require the one used
      require "guard/jobs/sleep"
      require "guard/jobs/pry_wrapper"

      job_klass = interactive? ? Jobs::PryWrapper : Jobs::Sleep
      @idle_job = job_klass.new(self.class.options)
    end

    def interactive?
      @interactive
    end

    extend Forwardable
    delegate [:foreground, :background, :handle_interrupt] => :idle_job

    # TODO: everything below is just so the DSL can set options
    # before setup() is called, which makes it useless for when
    # Guardfile is reevaluated
    class << self
      def options
        @options ||= {}
      end

      # Pass options to interactor's job when it's created
      attr_writer :options

      # TODO: allow custom user idle jobs, e.g. [:pry, :sleep, :exit, ...]
      def enabled?
        @enabled || @enabled.nil?
      end

      alias_method :enabled, :enabled?

      # TODO: handle switching interactors during runtime?
      attr_writer :enabled
    end

    private

    attr_reader :idle_job
  end
end
