require "thread"
require "listen"

require "guard/config"
require "guard/deprecated/guard" unless Guard::Config.new.strict?
require "guard/internals/helpers"

require "guard/internals/debugging"
require "guard/internals/traps"
require "guard/internals/queue"

# TODO: remove this class altogether
require "guard/interactor"

# Guard is the main module for all Guard related modules and classes.
# Also Guard plugins should use this namespace.
module Guard
  Deprecated::Guard.add_deprecated(self) unless Config.new.strict?

  class << self
    attr_reader :state
    attr_reader :queue
    attr_reader :listener
    attr_reader :interactor

    # @private api

    include Internals::Helpers

    # Initializes the Guard singleton:
    #
    # * Initialize the internal Guard state;
    # * Create the interactor
    # * Select and initialize the file change listener.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [Array<String>] watchdir the directories to watch
    # @option options [String] guardfile the path to the Guardfile
    #
    # @return [Guard] the Guard singleton
    def setup(cmdline_options = {})
      init(cmdline_options)

      @queue = Internals::Queue.new(Guard)

      _evaluate(state.session.evaluator_options)

      # NOTE: this should be *after* evaluate so :directories can work
      # TODO: move listener setup to session?
      @listener = Listen.send(*state.session.listener_args, &_listener_callback)

      ignores = state.session.guardfile_ignore
      @listener.ignore(ignores) unless ignores.empty?

      ignores = state.session.guardfile_ignore_bang
      @listener.ignore!(ignores) unless ignores.empty?

      Notifier.connect(state.session.notify_options)

      traps = Internals::Traps
      traps.handle("USR1") { async_queue_add([:guard_pause, :paused]) }
      traps.handle("USR2") { async_queue_add([:guard_pause, :unpaused]) }

      @interactor = Interactor.new(state.session.interactor_name == :sleep)
      traps.handle("INT") { @interactor.handle_interrupt }

      self
    end

    def init(cmdline_options)
      @state = Internals::State.new(cmdline_options)
    end

    # Asynchronously trigger changes
    #
    # Currently supported args:
    #
    #   @example Old style hash:
    #     async_queue_add(modified: ['foo'], added: ['bar'], removed: [])
    #
    #   @example New style signals with args:
    #     async_queue_add([:guard_pause, :unpaused ])
    #
    def async_queue_add(changes)
      @queue << changes

      # Putting interactor in background puts guard into foreground
      # so it can handle change notifications
      Thread.new { interactor.background }
    end

    private

    # Check if any of the changes are actually watched for
    # TODO: why iterate twice? reuse this info when running tasks
    def _relevant_changes?(changes)
      # TODO: no coverage!
      files = changes.values.flatten(1)
      scope = Guard.state.scope
      watchers = scope.grouped_plugins.map do |_group, plugins|
        plugins.map(&:watchers).flatten
      end.flatten
      watchers.any? { |watcher| files.any? { |file| watcher.match(file) } }
    end

    def _relative_pathnames(paths)
      paths.map { |path| _relative_pathname(path) }
    end

    def _listener_callback
      lambda do |modified, added, removed|
        relative_paths = {
          modified: _relative_pathnames(modified),
          added: _relative_pathnames(added),
          removed: _relative_pathnames(removed)
        }

        _guardfile_deprecated_check(relative_paths[:modified])

        async_queue_add(relative_paths) if _relevant_changes?(relative_paths)
      end
    end

    # TODO: obsoleted? (move to Dsl?)
    def _pluginless_guardfile?
      state.session.plugins.all.empty?
    end

    def _evaluate(options)
      evaluator = Guardfile::Evaluator.new(options)
      evaluator.evaluate

      UI.reset_and_clear

      msg = "No plugins found in Guardfile, please add at least one."
      UI.error msg if _pluginless_guardfile?

      if evaluator.inline?
        UI.info("Using inline Guardfile.")
      elsif evaluator.custom?
        UI.info("Using Guardfile at #{ evaluator.path }.")
      end
    rescue Guardfile::Evaluator::NoPluginsError => e
      UI.error(e.message)
    end

    # TODO: remove at some point
    # TODO: not tested because collides with ongoing refactoring
    def _guardfile_deprecated_check(modified)
      modified.map!(&:to_s)
      regexp = %r{^(?:.+/)?Guardfile$}
      guardfiles = modified.select { |path| regexp.match(path) }
      return if guardfiles.empty?

      guardfile = Pathname("Guardfile").realpath
      real_guardfiles = guardfiles.detect do |path|
        /^Guardfile$/.match(path) || Pathname(path).expand_path == guardfile
      end

      return unless real_guardfiles

      UI.warning "Guardfile changed -- _guard-core will exit.\n"
      exit 2 # nonzero to break any while loop
    end
  end
end
