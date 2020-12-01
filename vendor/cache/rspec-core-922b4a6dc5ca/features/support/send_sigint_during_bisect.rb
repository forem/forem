require 'rspec/core'
RSpec::Support.require_rspec_core "formatters/bisect_progress_formatter"

module RSpec::Core::Formatters
  BisectProgressFormatter = Class.new(remove_const :BisectProgressFormatter) do
    RSpec::Core::Formatters.register self

    def bisect_round_started(notification)
      return super unless @round_count == 3

      Process.kill("INT", Process.pid)
      # Process.kill is not a synchronous call, so to ensure the output
      # below aborts at a deterministic place, we need to block here.
      # The sleep will be interrupted by the signal once the OS sends it.
      # For the most part, this is only needed on JRuby, but we saw
      # the asynchronous behavior on an MRI 2.0 travis build as well.
      sleep 5
    end
  end
end

