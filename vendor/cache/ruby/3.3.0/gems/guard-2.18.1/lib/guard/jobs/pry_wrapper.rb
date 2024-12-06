require "guard/commands/all"
require "guard/commands/change"
require "guard/commands/notification"
require "guard/commands/pause"
require "guard/commands/reload"
require "guard/commands/scope"
require "guard/commands/show"
require "shellany/sheller"

require "guard/jobs/base"

module Guard
  module Jobs
    class TerminalSettings
      def initialize
        @settings = nil
        @works = Shellany::Sheller.run("hash", "stty") || false
      end

      def restore
        return unless configurable? && @settings
        Shellany::Sheller.run("stty #{ @setting } 2>#{IO::NULL}")
      end

      def save
        return unless configurable?
        @settings = Shellany::Sheller.stdout("stty -g 2>#{IO::NULL}").chomp
      end

      def echo
        return unless configurable?
        Shellany::Sheller.run("stty echo 2>#{IO::NULL}")
      end

      def configurable?
        @works
      end
    end

    class PryWrapper < Base
      # The default Ruby script to configure Guard Pry if the option `:guard_rc`
      # is not defined.

      GUARD_RC = if ENV["XDG_CONFIG_HOME"] && File.exist?(ENV["XDG_CONFIG_HOME"] + "/guard/guardrc")
                   ENV["XDG_CONFIG_HOME"] + "/guard/guardrc"
                 else
                   "~/.guardrc"
                 end

      # The default Guard Pry history file if the option `:history_file` is not
      # defined.

      HISTORY_FILE = if ENV["XDG_DATA_HOME"] && File.exist?(ENV["XDG_DATA_HOME"] + "/guard/history")
                       ENV["XDG_DATA_HOME"] + "/guard/history"
                     else
                       "~/.guard_history"
                     end

      # List of shortcuts for each interactor command
      SHORTCUTS = {
        help: "h",
        all: "a",
        reload: "r",
        change: "c",
        show: "s",
        scope: "o",
        notification: "n",
        pause: "p",
        exit: "e",
        quit: "q"
      }

      def initialize(options)
        @mutex = Mutex.new
        @thread = nil
        @terminal_settings = TerminalSettings.new

        _setup(options)
      end

      def foreground
        UI.debug "Start interactor"
        @terminal_settings.save

        _switch_to_pry
        # TODO: rename :stopped to continue
        _killed? ? :stopped : :exit
      ensure
        UI.reset_line
        UI.debug "Interactor was stopped or killed"
        @terminal_settings.restore
      end

      def background
        _kill_pry
      end

      def handle_interrupt
        thread = @thread
        fail Interrupt unless thread
        thread.raise Interrupt
      end

      private

      attr_reader :thread

      def _pry_config
        Pry.config
      end

      def _pry_commands
        Pry.commands
      end

      def _switch_to_pry
        th = nil
        @mutex.synchronize do
          unless @thread
            @thread = Thread.new { Pry.start }
            @thread.join(0.5) # give pry a chance to start
            th = @thread
          end
        end
        # check for nill, because it might've been killed between the mutex and
        # now
        th.join unless th.nil?
      end

      def _killed?
        th = nil
        @mutex.synchronize { th = @thread }
        th.nil?
      end

      def _kill_pry
        @mutex.synchronize do
          unless @thread.nil?
            @thread.kill
            @thread = nil # set to nil so we know we were killed
          end
        end
      end

      def _setup(options)
        _pry_config.should_load_rc = false
        _pry_config.should_load_local_rc = false

        _configure_history_file(options[:history_file] || HISTORY_FILE)
        _add_hooks(options)

        Commands::All.import
        Commands::Change.import
        Commands::Notification.import
        Commands::Pause.import
        Commands::Reload.import
        Commands::Show.import
        Commands::Scope.import

        _setup_commands
        _configure_prompt
      end

      def _configure_history_file(history_file)
        history_file_path = File.expand_path(history_file)

        # Pry >= 0.13
        if _pry_config.respond_to?(:history_file=)
          _pry_config.history_file = history_file_path
        else
          _pry_config.history.file = history_file_path
        end
      end

      # Add Pry hooks:
      #
      # * Load `~/.guardrc` within each new Pry session.
      # * Load project's `.guardrc` within each new Pry session.
      # * Restore prompt after each evaluation.
      #
      def _add_hooks(options)
        _add_load_guard_rc_hook(Pathname(options[:guard_rc] || GUARD_RC))
        _add_load_project_guard_rc_hook(Pathname.pwd + ".guardrc")
        _add_restore_visibility_hook if @terminal_settings.configurable?
      end

      # Add a `when_started` hook that loads a global .guardrc if it exists.
      #
      def _add_load_guard_rc_hook(guard_rc)
        _pry_config.hooks.add_hook :when_started, :load_guard_rc do
          guard_rc.expand_path.tap { |p| load p if p.exist? }
        end
      end

      # Add a `when_started` hook that loads a project .guardrc if it exists.
      #
      def _add_load_project_guard_rc_hook(guard_rc)
        _pry_config.hooks.add_hook :when_started, :load_project_guard_rc do
          load guard_rc if guard_rc.exist?
        end
      end

      # Add a `after_eval` hook that restores visibility after a command is
      # eval.
      def _add_restore_visibility_hook
        _pry_config.hooks.add_hook :after_eval, :restore_visibility do
          @terminal_settings.echo
        end
      end

      def _setup_commands
        _replace_reset_command
        _create_run_all_command
        _create_command_aliases
        _create_guard_commands
        _create_group_commands
      end

      # Replaces reset defined inside of Pry with a reset that
      # instead restarts guard.
      #
      def _replace_reset_command
        _pry_commands.command "reset", "Reset the Guard to a clean state." do
          output.puts "Guard reset."
          exec "guard"
        end
      end

      # Creates a command that triggers the `:run_all` action
      # when the command is empty (just pressing enter on the
      # beginning of a line).
      #
      def _create_run_all_command
        _pry_commands.block_command(/^$/, "Hit enter to run all") do
          Pry.run_command "all"
        end
      end

      # Creates command aliases for the commands: `help`, `reload`, `change`,
      # `scope`, `notification`, `pause`, `exit` and `quit`, which will be the
      # first letter of the command.
      #
      def _create_command_aliases
        SHORTCUTS.each do |command, shortcut|
          _pry_commands.alias_command shortcut, command.to_s
        end
      end

      # Create a shorthand command to run the `:run_all`
      # action on a specific Guard plugin. For example,
      # when guard-rspec is available, then a command
      # `rspec` is created that runs `all rspec`.
      #
      def _create_guard_commands
        Guard.state.session.plugins.all.each do |guard_plugin|
          cmd = "Run all #{guard_plugin.title}"
          _pry_commands.create_command guard_plugin.name, cmd do
            group "Guard"

            def process
              Pry.run_command "all #{ match }"
            end
          end
        end
      end

      # Create a shorthand command to run the `:run_all`
      # action on a specific Guard group. For example,
      # when you have a group `frontend`, then a command
      # `frontend` is created that runs `all frontend`.
      #
      def _create_group_commands
        Guard.state.session.groups.all.each do |group|
          next if group.name == :default

          cmd = "Run all #{group.title}"
          _pry_commands.create_command group.name.to_s, cmd do
            group "Guard"

            def process
              Pry.run_command "all #{ match }"
            end
          end
        end
      end

      # Configures the pry prompt to see `guard` instead of
      # `pry`.
      #
      def _configure_prompt
        prompt_procs = [_prompt(">"), _prompt("*")]
        prompt =
          if Pry::Prompt.is_a?(Class)
            Pry::Prompt.new("Guard", "Guard Pry prompt", prompt_procs)
          else
            prompt_procs
          end

        _pry_config.prompt = prompt
      end

      # Returns the plugins scope, or the groups scope ready for display in the
      # prompt.
      #
      def _scope_for_prompt
        titles = Guard.state.scope.titles.join(",")
        titles == "all" ? "" : titles + " "
      end

      # Returns a proc that will return itself a string ending with the given
      # `ending_char` when called.
      #
      def _prompt(ending_char)
        proc do |target_self, nest_level, pry|
          process = Guard.listener.paused? ? "pause" : "guard"
          level = ":#{ nest_level }" unless nest_level.zero?

          "[#{ _history(pry) }] #{ _scope_for_prompt }#{ process }"\
            "(#{ _clip_name(target_self) })#{ level }#{ ending_char } "
        end
      end

      def _clip_name(target)
        Pry.view_clip(target)
      end

      def _history(pry)
        if pry.respond_to?(:input_ring)
          pry.input_ring.size
        else
          pry.input_array.size
        end
      end
    end
  end
end
