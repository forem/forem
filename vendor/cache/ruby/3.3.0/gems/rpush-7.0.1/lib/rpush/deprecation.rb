module Rpush
  class Deprecation
    def self.muted
      orig_val = Thread.current[:rpush_mute_deprecations]
      Thread.current[:rpush_mute_deprecations] = true
      yield
    ensure
      Thread.current[:rpush_mute_deprecations] = orig_val
    end

    def self.muted?
      Thread.current[:rpush_mute_deprecations] == true
    end

    def self.warn(msg)
      return if Rpush::Deprecation.muted?
      STDERR.puts "DEPRECATION WARNING: #{msg}"
    end

    def self.warn_with_backtrace(msg)
      return if Rpush::Deprecation.muted?
      trace = "\n\nCALLED FROM:\n" + caller.join("\n")
      warn(msg + trace)
    end
  end
end
