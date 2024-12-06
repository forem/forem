module Backport
  # The application interface between Backport servers and clients.
  #
  class Adapter
    # @param output [IO]
    # @param remote [Hash{Symbol => String, Integer}]
    def initialize output, remote = {}
      # Store internal data in a singleton method to avoid instance variable
      # collisions in custom adapters
      data = {
        out: output,
        remote: remote,
        closed: false
      }
      define_singleton_method :_data do
        data
      end
    end

    # A hash of information about the client connection. The data can vary
    # based on the transport, e.g., :hostname and :address for TCP connections
    # or :filename for file streams.
    #
    # @return [Hash{Symbol => String, Integer}]
    def remote
      _data[:remote]
    end

    # A callback triggered when a client connection is opening. Subclasses
    # and/or modules should override this method to provide their own
    # functionality.
    #
    # @return [void]
    def opening; end

    # A callback triggered when a client connection is closing. Subclasses
    # and/or modules should override this method to provide their own
    # functionality.
    #
    # @return [void]
    def closing; end

    # A callback triggered when the server receives data from the client.
    # Subclasses and/or modules should override this method to provide their
    # own functionality.
    #
    # @param data [String]
    # @return [void]
    def receiving(data); end

    # Send data to the client.
    #
    # @param data [String]
    # @return [void]
    def write data
      _data[:out].write data
      _data[:out].flush
    end

    # Send a line of data to the client.
    #
    # @param data [String]
    # @return [void]
    def write_line data
      _data[:out].puts data
      _data[:out].flush
    end

    def closed?
      _data[:closed] ||= false
    end

    # Close the client connection.
    #
    # @note The adapter sets #closed? to true and runs the #closing callback.
    #   The server is responsible for implementation details like closing the
    #   client's socket.
    #
    # @return [void]
    def close
      return if closed?
      _data[:closed] = true
      _data[:on_close].call unless _data[:on_close].nil?
      closing
    end
  end
end
