require 'base64'
module HTTP2
  # HTTP 2.0 server connection class that implements appropriate header
  # compression / decompression algorithms and stream management logic.
  #
  # Your code is responsible for feeding request data to the server object,
  # which in turn performs all of the necessary HTTP 2.0 decoding / encoding,
  # state management, and the rest. A simple example:
  #
  # @example
  #     socket = YourTransport.new
  #
  #     conn = HTTP2::Server.new
  #     conn.on(:stream) do |stream|
  #       ...
  #     end
  #
  #     while bytes = socket.read
  #       conn << bytes
  #     end
  #
  class Server < Connection
    # Initialize new HTTP 2.0 server object.
    def initialize(**settings)
      @stream_id    = 2
      @state        = :waiting_magic

      @local_role   = :server
      @remote_role  = :client

      super
    end

    #   GET / HTTP/1.1
    #   Host: server.example.com
    #   Connection: Upgrade, HTTP2-Settings
    #   Upgrade: h2c
    #   HTTP2-Settings: <base64url encoding of HTTP/2 SETTINGS payload>
    #
    # Requests that contain a payload body MUST be sent in their entirety
    # before the client can send HTTP/2 frames. This means that a large
    # request can block the use of the connection until it is completely sent.
    #
    # If concurrency of an initial request with subsequent requests is
    # important, an OPTIONS request can be used to perform the upgrade to
    # HTTP/2, at the cost of an additional round trip.
    #
    #   HTTP/1.1 101 Switching Protocols
    #   Connection: Upgrade
    #   Upgrade: h2c
    #
    #   [ HTTP/2 connection ...
    #
    # - The first HTTP/2 frame sent by the server MUST be a server
    #   connection preface (Section 3.5) consisting of a SETTINGS frame.
    # - Upon receiving the 101 response, the client MUST send a connection
    #   preface (Section 3.5), which includes a SETTINGS frame.
    #
    # The HTTP/1.1 request that is sent prior to upgrade is assigned a stream
    # identifier of 1 (see Section 5.1.1) with default priority values
    # (Section 5.3.5). Stream 1 is implicitly "half-closed" from the client
    # toward the server (see Section 5.1), since the request is completed as
    # an HTTP/1.1 request. After commencing the HTTP/2 connection, stream 1
    # is used for the response.
    #
    def upgrade(settings, headers, body)
      @h2c_upgrade = :start

      # Pretend that we've received the preface
      #  - puts us into :waiting_connection_preface state
      #  - emits a SETTINGS frame to the client
      receive(CONNECTION_PREFACE_MAGIC)

      # Process received HTTP2-Settings payload
      buf = HTTP2::Buffer.new Base64.urlsafe_decode64(settings.to_s)
      header = @framer.common_header(
        length: buf.bytesize,
        type: :settings,
        stream: 0,
        flags: [],
      )
      buf.prepend(header)
      receive(buf)

      # Activate stream (id: 1) with on HTTP/1.1 request parameters
      stream = activate_stream(id: 1)
      emit(:stream, stream)

      headers_frame = {
        type:       :headers,
        stream:     1,
        weight:     DEFAULT_WEIGHT,
        dependency: 0,
        exclusive:  false,
        payload: headers,
      }

      if body.empty?
        headers_frame.merge!(flags: [:end_stream])
        stream << headers_frame
      else
        stream << headers_frame
        stream << { type: :data, stream: 1, payload: body, flags: [:end_stream] }
      end

      # Mark h2c upgrade as finished
      @h2c_upgrade = :finished

      # Transition back to :waiting_magic and wait for client's preface
      @state = :waiting_magic
    end

    private

    # Handle locally initiated server-push event emitted by the stream.
    #
    # @param args [Array]
    # @param callback [Proc]
    def promise(*args, &callback)
      parent, headers, flags = *args
      promise = new_stream(parent: parent)
      promise.send(
        type: :push_promise,
        flags: flags,
        stream: parent.id,
        promise_stream: promise.id,
        payload: headers.to_a,
      )

      callback.call(promise)
    end
  end
end
