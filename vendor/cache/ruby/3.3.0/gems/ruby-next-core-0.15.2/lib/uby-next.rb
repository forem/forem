# frozen_string_literal: true

# Activate all features
ENV["RUBY_NEXT_EDGE"] = "1"
ENV["RUBY_NEXT_PROPOSED"] = "1"

require "ruby-next/language/runtime"
require "ruby-next/core/runtime"

using RubyNext

RubyNext::Language.watch_dirs << Dir.pwd

require "stringio"

# Hijack stderr to avoid printing exceptions while executing ruby files
stderr = StringIO.new

orig_stderr, $stderr = $stderr, stderr

# Capture source code passed via `-e` option
e_script = nil

if $0 == "-e"
  begin
    TracePoint.new(:script_compiled) do |tp|
      next unless tp.path == "-e"
      e_script = tp.eval_script
      tp.disable
    end.enable
  rescue ArgumentError
    # script_compiled event is not supported
  end
end

at_exit do
  $stderr = orig_stderr

  if NoMethodError === $! || SyntaxError === $!
    if $0 && File.exist?($0)
      load($0)
      exit!(0)
    end

    if $0 == "-e" && e_script.nil?
      if File.file?("/proc/self/cmdline")
        File.read("/proc/self/cmdline")
      else
        `ps axw`.split("\n").find { |ps| ps[/\A\s*#{$$}/] }
      end.then do |command|
        next unless command
        command.gsub!(/(\\012|\u0000)/, "\n")
        command.match(/-e(.*)/m)
      end.then do |matches|
        next unless matches

        args = ["-e", matches[1]]
        require "optparse"
        OptionParser.new do |o|
          o.on("-e SOURCE") do |v|
            e_script = v
          end
        end.parse!(args)
      end
    end

    if e_script
      new_e_script = RubyNext::Language::Runtime.transform(e_script)
      RubyNext.debug_source new_e_script, $0
      TOPLEVEL_BINDING.eval(new_e_script, $0)
      exit!(0)
    end
  end

  puts(stderr.tap(&:rewind).read)
end
