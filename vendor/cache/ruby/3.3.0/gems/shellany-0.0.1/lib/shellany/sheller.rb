require "open3"

module Shellany
  # The Guard sheller abstract the actual subshell
  # calls and allow easier stubbing.
  #
  class Sheller
    attr_reader :status

    # Creates a new Guard::Sheller object.
    #
    # @param [String] args a command to run in a subshell
    # @param [Array<String>] args an array of command parts to run in a subshell
    # @param [*String] args a list of command parts to run in a subshell
    #
    def initialize(*args)
      fail ArgumentError, "no command given" if args.empty?
      @command = args
      @ran = false
    end

    # Shortcut for new(command).run
    #
    def self.run(*args)
      new(*args).run
    end

    # Shortcut for new(command).run.stdout
    #
    def self.stdout(*args)
      new(*args).stdout
    end

    # Shortcut for new(command).run.stderr
    #
    def self.stderr(*args)
      new(*args).stderr
    end

    # Runs the command.
    #
    # @return [Boolean] whether or not the command succeeded.
    #
    def run
      unless ran?
        status, output, errors = self.class._system_with_capture(*@command)
        @ran = true
        @stdout = output
        @stderr = errors
        @status = status
      end

      ok?
    end

    # Returns true if the command has already been run, false otherwise.
    #
    # @return [Boolean] whether or not the command has already been run
    #
    def ran?
      @ran
    end

    # Returns true if the command succeeded, false otherwise.
    #
    # @return [Boolean] whether or not the command succeeded
    #
    def ok?
      run unless ran?

      @status && @status.success?
    end

    # Returns the command's output.
    #
    # @return [String] the command output
    #
    def stdout
      run unless ran?

      @stdout
    end

    # Returns the command's error output.
    #
    # @return [String] the command output
    #
    def stderr
      run unless ran?

      @stderr
    end

    # No output capturing
    #
    # NOTE: `$stdout.puts system('cls')` on Windows won't work like
    # it does for on systems with ansi terminals, so we need to be
    # able to call Kernel.system directly.
    def self.system(*args)
      _system_with_no_capture(*args)
    end

    def self._system_with_no_capture(*args)
      Kernel.system(*args)
      result = $?
      errors = (result == 0) || "Guard failed to run: #{args.inspect}"
      [result, nil, errors]
    end

    def self._system_with_capture(*args)
      # We use popen3, because it started working on recent versions
      # of JRuby, while JRuby doesn't handle options to Kernel.system
      args = _shellize_if_needed(args)

      stdout, stderr, status = nil
      Open3.popen3(*args) do |_stdin, _stdout, _stderr, _thr|
        stdout = _stdout.read
        stderr = _stderr.read
        status = _thr.value
      end

      [status, stdout, stderr]
    rescue Errno::ENOENT, IOError => e
      [nil, nil, "Guard::Sheller failed (#{e.inspect})"]
    end

    # Only needed on JRUBY, because MRI properly detects ';' and metachars
    def self._shellize_if_needed(args)
      return args unless RUBY_PLATFORM == "java"
      return args unless args.size == 1
      return args unless /[;<>]/ =~ args.first

      # NOTE: Sheller was originally meant for Guard (which basically only uses
      # UNIX commands anyway) and JRuby doesn't support options to
      # Kernel.system (and doesn't automatically shell when there's a
      # metacharacter in the command).
      #
      # So ... I'm assuming /bin/sh exists - if not, PRs are welcome,
      # because I have no clue what to do if /bin/sh doesn't exist.
      # (use ENV["RUBYSHELL"] ? Detect cmd.exe ?)
      ["/bin/sh", "-c", args.first]
    end
  end
end
