module HTTP2
  # Stream, connection, and compressor exceptions.
  module Error
    class Error < StandardError; end

    # Raised if connection header is missing or invalid indicating that
    # this is an invalid HTTP 2.0 request - no frames are emitted and the
    # connection must be aborted.
    class HandshakeError < Error; end

    # Raised by stream or connection handlers, results in GOAWAY frame
    # which signals termination of the current connection. You *cannot*
    # recover from this exception, or any exceptions subclassed from it.
    class ProtocolError < Error; end

    # Raised on any header encoding / decoding exception.
    #
    # @see ProtocolError
    class CompressionError < ProtocolError; end

    # Raised on invalid flow control frame or command.
    #
    # @see ProtocolError
    class FlowControlError < ProtocolError; end

    # Raised on invalid stream processing: invalid frame type received or
    # sent, or invalid command issued.
    class InternalError < ProtocolError; end

    #
    # -- Recoverable errors -------------------------------------------------
    #

    # Raised if stream has been closed and new frames cannot be sent.
    class StreamClosed < Error; end

    # Raised if connection has been closed (or draining) and new stream
    # cannot be opened.
    class ConnectionClosed < Error; end

    # Raised if stream limit has been reached and new stream cannot be opened.
    class StreamLimitExceeded < Error; end
  end
end
