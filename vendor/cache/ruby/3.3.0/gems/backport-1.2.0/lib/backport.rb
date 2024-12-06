require 'backport/version'
require 'logger'

# An event-driven IO library.
#
module Backport
  autoload :Adapter, 'backport/adapter'
  autoload :Machine, 'backport/machine'
  autoload :Server,  'backport/server'
  autoload :Client,  'backport/client'

  class << self
    # Prepare a STDIO server to run in Backport.
    #
    # @param adapter [Adapter]
    # @return [void]
    def prepare_stdio_server adapter: Adapter
      machines.last.prepare Backport::Server::Stdio.new(adapter: adapter)
    end

    # Prepare a TCP server to run in Backport.
    #
    # @param host [String]
    # @param port [Integer]
    # @param adapter [Adapter]
    # @return [void]
    def prepare_tcp_server host: 'localhost', port: 1117, adapter: Adapter
      machines.last.prepare Backport::Server::Tcpip.new(host: host, port: port, adapter: adapter)
    end

    # Prepare an interval server to run in Backport.
    #
    # @param period [Float] Seconds between intervals
    # @return [void]
    def prepare_interval period, &block
      machines.last.prepare Backport::Server::Interval.new(period, &block)
    end

    # Run the Backport machine. The provided block will be executed before the
    # machine starts. Program execution is blocked until the machine stops.
    #
    # @example Print "tick" once per second
    #   Backport.run do
    #     Backport.prepare_interval 1 do
    #       puts "tick"
    #     end
    #   end
    #
    # @return [void]
    def run &block
      machine = Machine.new
      machines.push machine
      machine.run &block
      machines.delete machine
    end

    # Stop all running Backport machines.
    #
    # For more accurate control, consider stopping the machine
    # from the self reference in Machine#run, e.g.:
    #
    # ```
    # Backport.run do |machine|
    #   # ...
    #   machine.stop
    # end
    # ```
    #
    # @return [void]
    def stop
      machines.last.stop unless machines.empty?
    end

    # @return [Logger]
    def logger
      @logger ||= Logger.new(STDERR, level: Logger::WARN, progname: 'Backport')
    end

    private

    # @return [Array<Machine>]
    def machines
      @machines ||= []
    end
  end
end
