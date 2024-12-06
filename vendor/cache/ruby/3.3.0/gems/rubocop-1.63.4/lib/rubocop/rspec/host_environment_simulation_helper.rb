# frozen_string_literal: true

# RuboCop can be run in contexts where unexpected other libraries are included,
# which may interfere with its normal behavior. In order to test those
# situations, it may be necessary to require another library for the duration
# of one spec
module HostEnvironmentSimulatorHelper
  def in_its_own_process_with(*files)
    if ::Process.respond_to?(:fork)
      pid = ::Process.fork do
        # Need to write coverage result under different name
        if defined?(SimpleCov)
          SimpleCov.command_name "rspec-fork-#{Process.pid}"
          SimpleCov.pid = Process.pid
        end

        files.each { |file| require file }
        yield
      end
      ::Process.wait(pid)

      # assert that the block did not fail
      expect($CHILD_STATUS).to be_success
    else
      warn 'Process.fork is not available.'
    end
  end
end
