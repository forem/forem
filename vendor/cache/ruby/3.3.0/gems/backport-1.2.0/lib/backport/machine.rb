module Backport
  # The Backport server controller.
  #
  class Machine
    def initialize
      @stopped = true
      @mutex = Mutex.new
    end

    # Run the machine. If a block is provided, it gets executed before the
    # maching starts its main loop. The main loop blocks program execution
    # until the machine is stopped.
    #
    # @yieldparam [self]
    # @return [void]
    def run
      return unless stopped?
      servers.clear
      @stopped = false
      yield self if block_given?
      run_server_thread
    end

    # Stop the machine.
    #
    # @return [void]
    def stop
      servers.map(&:stop)
      servers.clear
      @stopped = true
    end

    # True if the machine is stopped.
    #
    def stopped?
      @stopped ||= false
    end

    # Add a server to the machine. The server will be started when the machine
    # starts. If the machine is already running, the server will be started
    # immediately.
    #
    # @param server [Server::Base]
    # @return [void]
    def prepare server
      server.add_observer self
      servers.push server
      server.start unless stopped?
    end

    # @return [Array<Server::Base>]
    def servers
      @servers ||= []
    end

    # @param server [Server::Base]
    # @return [void]
    def update server
      if server.stopped?
        servers.delete server
        stop if servers.empty?
      else
        mutex.synchronize { server.tick }
      end
    end

    private

    # @return [Mutex]
    attr_reader :mutex

    # Start the thread that updates servers via the #tick method.
    #
    # @return [void]
    def run_server_thread
      servers.map(&:start)
      sleep 0.1 until stopped?
    end
  end
end
