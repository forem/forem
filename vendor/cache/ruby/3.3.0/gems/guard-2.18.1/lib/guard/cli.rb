require "thor"

require "guard/version"

require "guard/dsl_describer"
require "guard/cli/environments/valid"
require "guard/cli/environments/evaluate_only"

module Guard
  # Facade for the Guard command line interface managed by
  # [Thor](https://github.com/wycats/thor).
  #
  # This is the main interface to Guard that is called by the Guard binary
  # `bin/guard`. Do not put any logic in here, create a class and delegate
  # instead.
  #
  class CLI < Thor
    default_task :start

    desc "start", "Starts Guard"

    method_option :clear,
                  type: :boolean,
                  default: false,
                  aliases: "-c",
                  banner: "Auto clear shell before each action"

    method_option :notify,
                  type: :boolean,
                  default: true,
                  aliases: "-n",
                  banner: "Notifications feature"

    method_option :debug,
                  type: :boolean,
                  default: false,
                  aliases: "-d",
                  banner: "Show debug information"

    method_option :group,
                  type: :array,
                  default: [],
                  aliases: "-g",
                  banner: "Run only the passed groups"

    method_option :plugin,
                  type: :array,
                  default: [],
                  aliases: "-P",
                  banner: "Run only the passed plugins"

    # TODO: make it plural
    method_option :watchdir,
                  type: :array,
                  aliases: "-w",
                  banner: "Specify the directories to watch"

    method_option :guardfile,
                  type: :string,
                  aliases: "-G",
                  banner: "Specify a Guardfile"

    method_option :no_interactions,
                  type: :boolean,
                  default: false,
                  aliases: "-i",
                  banner: "Turn off completely any Guard terminal interactions"

    method_option :no_bundler_warning,
                  type: :boolean,
                  default: false,
                  aliases: "-B",
                  banner: "Turn off warning when Bundler is not present"

    # Listen options
    method_option :latency,
                  type: :numeric,
                  aliases: "-l",
                  banner: 'Overwrite Listen\'s default latency'

    method_option :force_polling,
                  type: :boolean,
                  default: false,
                  aliases: "-p",
                  banner: "Force usage of the Listen polling listener"

    method_option :wait_for_delay,
                  type: :numeric,
                  aliases: "-y",
                  banner: 'Overwrite Listen\'s default wait_for_delay'

    method_option :listen_on,
                  type: :string,
                  aliases: "-o",
                  default: nil,
                  banner: "Specify a network address to Listen on for "\
                  "file change events (e.g. for use in VMs)"

    def self.help(shell, subcommand = false)
      super
      command_help(shell, default_task)
    end

    # Start Guard by initializing the defined Guard plugins and watch the file
    # system.
    #
    # This is the default task, so calling `guard` is the same as calling
    # `guard start`.
    #
    # @see Guard.start
    #
    def start
      if defined?(JRUBY_VERSION)
        unless options[:no_interactions]
          abort "\nSorry, JRuby and interactive mode are incompatible.\n"\
            "As a workaround, use the '-i' option instead.\n\n"\
            "More info: \n"\
            " * https://github.com/guard/guard/issues/754\n"\
            " * https://github.com/jruby/jruby/issues/2383\n\n"
        end
      end
      exit(Cli::Environments::Valid.new(options).start_guard)
    end

    desc "list", "Lists Guard plugins that can be used with init"

    # List the Guard plugins that are available for use in your system and
    # marks those that are currently used in your `Guardfile`.
    #
    # @see Guard::DslDescriber.list
    #
    def list
      Cli::Environments::EvaluateOnly.new(options).evaluate
      DslDescriber.new.list
    end

    desc "notifiers", "Lists notifiers and its options"

    # List the Notifiers for use in your system.
    #
    # @see Guard::DslDescriber.notifiers
    #
    def notifiers
      Cli::Environments::EvaluateOnly.new(options).evaluate
      # TODO: pass the data directly to the notifiers?
      DslDescriber.new.notifiers
    end

    desc "version", "Show the Guard version"
    map %w(-v --version) => :version

    # Shows the current version of Guard.
    #
    # @see Guard::VERSION
    #
    def version
      $stdout.puts "Guard version #{ VERSION }"
    end

    desc "init [GUARDS]", "Generates a Guardfile at the current directory"\
      " (if it is not already there) and adds all installed Guard plugins"\
      " or the given GUARDS into it"

    method_option :bare,
                  type: :boolean,
                  default: false,
                  aliases: "-b",
                  banner: "Generate a bare Guardfile without adding any"\
                  " installed plugin into it"

    # Initializes the templates of all installed Guard plugins and adds them
    # to the `Guardfile` when no Guard name is passed. When passing
    # Guard plugin names it does the same but only for those Guard plugins.
    #
    # @see Guard::Guardfile.initialize_template
    # @see Guard::Guardfile.initialize_all_templates
    #
    # @param [Array<String>] plugin_names the name of the Guard plugins to
    # initialize
    #
    def init(*plugin_names)
      env = Cli::Environments::Valid.new(options)
      exitcode = env.initialize_guardfile(plugin_names)
      exit(exitcode)
    end

    desc "show", "Show all defined Guard plugins and their options"
    map %w(-T) => :show

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`
    #
    # @see Guard::DslDescriber.show
    #
    def show
      Cli::Environments::EvaluateOnly.new(options).evaluate
      DslDescriber.new.show
    end
  end
end
