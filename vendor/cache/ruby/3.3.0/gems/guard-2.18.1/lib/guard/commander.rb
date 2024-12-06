require "listen"

require "guard/notifier"
require "guard/interactor"
require "guard/runner"
require "guard/dsl_describer"

require "guard/internals/state"

module Guard
  # Commands supported by guard
  module Commander
    # Start Guard by evaluating the `Guardfile`, initializing declared Guard
    # plugins and starting the available file change listener.
    # Main method for Guard that is called from the CLI when Guard starts.
    #
    # - Setup Guard internals
    # - Evaluate the `Guardfile`
    # - Configure Notifiers
    # - Initialize the declared Guard plugins
    # - Start the available file change listener
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @see CLI#start
    #
    def start(options = {})
      setup(options)
      UI.debug "Guard starts all plugins"
      Runner.new.run(:start)
      listener.start

      watched = Guard.state.session.watchdirs.join("', '")
      UI.info "Guard is now watching at '#{ watched }'"

      exitcode = 0
      begin
        while interactor.foreground != :exit
          Guard.queue.process while Guard.queue.pending?
        end
      rescue Interrupt
      rescue SystemExit => e
        exitcode = e.status
      end

      exitcode
    ensure
      stop
    end

    def stop
      listener&.stop
      interactor&.background
      UI.debug "Guard stops all plugins"
      Runner.new.run(:stop)
      Notifier.disconnect
      UI.info "Bye bye...", reset: true
    end

    # Reload Guardfile and all Guard plugins currently enabled.
    # If no scope is given, then the Guardfile will be re-evaluated,
    # which results in a stop/start, which makes the reload obsolete.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def reload(scopes = {})
      UI.clear(force: true)
      UI.action_with_scopes("Reload", scopes)
      Runner.new.run(:reload, scopes)
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(scopes = {})
      UI.clear(force: true)
      UI.action_with_scopes("Run", scopes)
      Runner.new.run(:run_all, scopes)
    end

    # Pause Guard listening to file changes.
    #
    def pause(expected = nil)
      paused = listener.paused?
      states = { paused: true, unpaused: false, toggle: !paused }
      pause = states[expected || :toggle]
      fail ArgumentError, "invalid mode: #{expected.inspect}" if pause.nil?
      return if pause == paused

      listener.public_send(pause ? :pause : :start)
      UI.info "File event handling has been #{pause ? 'paused' : 'resumed'}"
    end

    def show
      DslDescriber.new.show
    end
  end
  extend Commander
end
