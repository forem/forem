require 'shellwords'
require 'stringio'

module Launchy::Detect
  class Runner
    class NotFoundError < Launchy::Error; end

    extend ::Launchy::DescendantTracker

    # Detect the current command runner
    #
    # This will return an instance of the Runner to be used to do the
    # application launching.
    #
    # If a runner cannot be detected then raise Runner::NotFoundError
    #
    # The runner rules are, in order:
    #
    # 1) If you are on windows, you use the Windows Runner no matter what
    # 2) If you are using the jruby engine, use the Jruby Runner. Unless rule
    #    (1) took effect
    # 3) Use Forkable (barring rules (1) and (2))
    def self.detect
      host_os_family = Launchy::Detect::HostOsFamily.detect
      ruby_engine    = Launchy::Detect::RubyEngine.detect

      return Windows.new if host_os_family.windows?
      if ruby_engine.jruby? then
        return Jruby.new
      end
      return Forkable.new
    end

    #
    # cut it down to just the shell commands that will be passed to exec or
    # posix_spawn. The cmd argument is split according to shell rules and the
    # args are not escaped because they whole set is passed to system as *args
    # and in that case system shell escaping rules are not done.
    #
    def shell_commands( cmd, args )
      cmdline = [ cmd.to_s.shellsplit ]
      cmdline << args.flatten.collect{ |a| a.to_s }
      return commandline_normalize( cmdline )
    end

    def commandline_normalize( cmdline )
      c = cmdline.flatten!
      c = c.find_all { |a| (not a.nil?) and ( a.size > 0 ) }
      Launchy.log "commandline_normalized => #{c.join(' ')}"
      return c
    end

    def dry_run( cmd, *args )
      shell_commands(cmd, args).join(" ")
    end

    def run( cmd, *args )
      raise Launchy::CommandNotFoundError, "No command found to run with args '#{args.join(' ')}'. If this is unexpected, #{Launchy.bug_report_message}" unless cmd
      if Launchy.dry_run? then
        $stdout.puts dry_run( cmd, *args )
      else
        wet_run( cmd, *args )
      end
    end


    #---------------------------------------
    # The list of known runners
    #---------------------------------------

    class Windows < Runner

      def all_args( cmd, *args )
        args = [ 'cmd', '/c', *shell_commands( cmd, *args ) ]
        Launchy.log "Windows: all_args => #{args.inspect}"
        return args
      end

      def dry_run( cmd, *args )
        all_args( cmd, *args ).join(" ")
      end

      # escape the reserved shell characters in windows command shell
      # http://technet.microsoft.com/en-us/library/cc723564.aspx
      #
      # Also make sure that the item after 'start' is guaranteed to be quoted.
      # https://github.com/copiousfreetime/launchy/issues/62
      def shell_commands( cmd, *args )
        parts = cmd.shellsplit

        if start_idx = parts.index('start') then
          title_idx = start_idx + 1
          title     = parts[title_idx]
          title     = title.sub(/^/,'"') unless title[0] == '"'
          title     = title.sub(/$/,'"') unless title[-1] == '"'
          parts[title_idx] = title
        end

        cmdline = [ parts ]
        cmdline << args.flatten.collect { |a| a.to_s.gsub(/([&|()<>^])/, "^\\1") }
        return commandline_normalize( cmdline )
      end

      def wet_run( cmd, *args )
        system( *all_args( cmd, *args ) )
      end
    end

    class Jruby < Runner
      def wet_run( cmd, *args )
        child_pid = spawn( *shell_commands( cmd, *args ) )
        Process.detach( child_pid )
      end
    end

    class Forkable < Runner
      attr_reader   :child_pid

      def wet_run( cmd, *args )
        @child_pid = fork do
          close_file_descriptors unless Launchy.debug?
          Launchy.log("wet_run: before exec in child process")
          exec_or_raise( cmd, *args )
          exit!
        end
        Process.detach( @child_pid )
      end

      private

      # attaching to a StringIO instead of reopening so we don't loose the
      # STDERR, needed for exec_or_raise.
      def close_file_descriptors
        $stdin.reopen( "/dev/null")

        @saved_stdout = $stdout
        @saved_stderr = $stderr

        $stdout       = StringIO.new
        $stderr       = StringIO.new
      end

      def exec_or_raise( cmd, *args )
        exec( *shell_commands( cmd, *args ))
      rescue Exception => e
        $stderr = @saved_stderr
        $stdout = @saved_stdout
        raise e
      end
    end
  end
end
