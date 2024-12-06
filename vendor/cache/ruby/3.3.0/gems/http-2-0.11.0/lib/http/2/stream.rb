module HTTP2
  # A single HTTP 2.0 connection can multiplex multiple streams in parallel:
  # multiple requests and responses can be in flight simultaneously and stream
  # data can be interleaved and prioritized.
  #
  # This class encapsulates all of the state, transition, flow-control, and
  # error management as defined by the HTTP 2.0 specification. All you have
  # to do is subscribe to appropriate events (marked with ":" prefix in
  # diagram below) and provide your application logic to handle request
  # and response processing.
  #
  #                         +--------+
  #                    PP   |        |   PP
  #                ,--------|  idle  |--------.
  #               /         |        |         \
  #              v          +--------+          v
  #       +----------+          |           +----------+
  #       |          |          | H         |          |
  #   ,---|:reserved |          |           |:reserved |---.
  #   |   | (local)  |          v           | (remote) |   |
  #   |   +----------+      +--------+      +----------+   |
  #   |      | :active      |        |      :active |      |
  #   |      |      ,-------|:active |-------.      |      |
  #   |      | H   /   ES   |        |   ES   \   H |      |
  #   |      v    v         +--------+         v    v      |
  #   |   +-----------+          |          +-----------+  |
  #   |   |:half_close|          |          |:half_close|  |
  #   |   |  (remote) |          |          |  (local)  |  |
  #   |   +-----------+          |          +-----------+  |
  #   |        |                 v                |        |
  #   |        |    ES/R    +--------+    ES/R    |        |
  #   |        `----------->|        |<-----------'        |
  #   | R                   | :close |                   R |
  #   `-------------------->|        |<--------------------'
  #                         +--------+
  class Stream
    include FlowBuffer
    include Emitter
    include Error

    # Stream ID (odd for client initiated streams, even otherwise).
    attr_reader :id

    # Stream state as defined by HTTP 2.0.
    attr_reader :state

    # Request parent stream of push stream.
    attr_reader :parent

    # Stream priority as set by initiator.
    attr_reader :weight
    attr_reader :dependency

    # Size of current stream flow control window.
    attr_reader :local_window
    attr_reader :remote_window
    alias window local_window

    # Reason why connection was closed.
    attr_reader :closed

    # Initializes new stream.
    #
    # Note that you should never have to call this directly. To create a new
    # client initiated stream, use Connection#new_stream. Similarly, Connection
    # will emit new stream objects, when new stream frames are received.
    #
    # @param id [Integer]
    # @param weight [Integer]
    # @param dependency [Integer]
    # @param exclusive [Boolean]
    # @param window [Integer]
    # @param parent [Stream]
    # @param state [Symbol]
    def initialize(connection:, id:, weight: 16, dependency: 0, exclusive: false, parent: nil, state: :idle)
      @connection = connection
      @id = id
      @weight = weight
      @dependency = dependency
      process_priority(weight: weight, stream_dependency: dependency, exclusive: exclusive)
      @local_window_max_size = connection.local_settings[:settings_initial_window_size]
      @local_window  = connection.local_settings[:settings_initial_window_size]
      @remote_window = connection.remote_settings[:settings_initial_window_size]
      @parent = parent
      @state  = state
      @error  = false
      @closed = false
      @send_buffer = []

      on(:window) { |v| @remote_window = v }
      on(:local_window) { |v| @local_window_max_size = @local_window = v }
    end

    def closed?
      @state == :closed
    end

    # Processes incoming HTTP 2.0 frames. The frames must be decoded upstream.
    #
    # @param frame [Hash]
    def receive(frame)
      transition(frame, false)

      case frame[:type]
      when :data
        update_local_window(frame)
        # Emit DATA frame
        emit(:data, frame[:payload]) unless frame[:ignore]
        calculate_window_update(@local_window_max_size)
      when :headers
        emit(:headers, frame[:payload]) unless frame[:ignore]
      when :push_promise
        emit(:promise_headers, frame[:payload]) unless frame[:ignore]
      when :priority
        process_priority(frame)
      when :window_update
        process_window_update(frame)
      when :altsvc
        # 4.  The ALTSVC HTTP/2 Frame
        # An ALTSVC frame on a
        # stream other than stream 0 containing non-empty "Origin" information
        # is invalid and MUST be ignored.
        if !frame[:origin] || frame[:origin].empty?
          emit(frame[:type], frame)
        end
      when :blocked
        emit(frame[:type], frame)
      end

      complete_transition(frame)
    end
    alias << receive

    # Processes outgoing HTTP 2.0 frames. Data frames may be automatically
    # split and buffered based on maximum frame size and current stream flow
    # control window size.
    #
    # @param frame [Hash]
    def send(frame)
      process_priority(frame) if frame[:type] == :priority

      case frame[:type]
      when :data
        # @remote_window is maintained in send_data
        send_data(frame)
      when :window_update
        manage_state(frame) do
          @local_window += frame[:increment]
          emit(:frame, frame)
        end
      else
        manage_state(frame) do
          emit(:frame, frame)
        end
      end
    end

    # Sends a HEADERS frame containing HTTP response headers.
    # All pseudo-header fields MUST appear in the header block before regular header fields.
    #
    # @param headers [Array or Hash] Array of key-value pairs or Hash
    # @param end_headers [Boolean] indicates that no more headers will be sent
    # @param end_stream [Boolean] indicates that no payload will be sent
    def headers(headers, end_headers: true, end_stream: false)
      flags = []
      flags << :end_headers if end_headers
      flags << :end_stream  if end_stream

      send(type: :headers, flags: flags, payload: headers)
    end

    def promise(headers, end_headers: true, &block)
      fail ArgumentError, 'must provide callback' unless block_given?

      flags = end_headers ? [:end_headers] : []
      emit(:promise, self, headers, flags, &block)
    end

    # Sends a PRIORITY frame with new stream priority value (can only be
    # performed by the client).
    #
    # @param weight [Integer] new stream weight value
    # @param dependency [Integer] new stream dependency stream
    def reprioritize(weight: 16, dependency: 0, exclusive: false)
      stream_error if @id.even?
      send(type: :priority, weight: weight, stream_dependency: dependency, exclusive: exclusive)
    end

    # Sends DATA frame containing response payload.
    #
    # @param payload [String]
    # @param end_stream [Boolean] indicates last response DATA frame
    def data(payload, end_stream: true)
      # Split data according to each frame is smaller enough
      # TODO: consider padding?
      max_size = @connection.remote_settings[:settings_max_frame_size]

      if payload.bytesize > max_size
        payload = chunk_data(payload, max_size) do |chunk|
          send(type: :data, flags: [], payload: chunk)
        end
      end

      flags = []
      flags << :end_stream if end_stream
      send(type: :data, flags: flags, payload: payload)
    end

    # Chunk data into max_size, yield each chunk, then return final chunk
    #
    def chunk_data(payload, max_size)
      total = payload.bytesize
      cursor = 0
      while (total - cursor) > max_size
        yield payload.byteslice(cursor, max_size)
        cursor += max_size
      end
      payload.byteslice(cursor, total - cursor)
    end

    # Sends a RST_STREAM frame which closes current stream - this does not
    # close the underlying connection.
    #
    # @param error [:Symbol] optional reason why stream was closed
    def close(error = :stream_closed)
      send(type: :rst_stream, error: error)
    end

    # Sends a RST_STREAM indicating that the stream is no longer needed.
    def cancel
      send(type: :rst_stream, error: :cancel)
    end

    # Sends a RST_STREAM indicating that the stream has been refused prior
    # to performing any application processing.
    def refuse
      send(type: :rst_stream, error: :refused_stream)
    end

    # Sends a WINDOW_UPDATE frame to the peer.
    #
    # @param increment [Integer]
    def window_update(increment)
      # emit stream-level WINDOW_UPDATE unless stream is closed
      return if @state == :closed || @state == :remote_closed
      send(type: :window_update, increment: increment)
    end

    private

    # HTTP 2.0 Stream States
    # - http://tools.ietf.org/html/draft-ietf-httpbis-http2-16#section-5.1
    #
    #                         +--------+
    #                 send PP |        | recv PP
    #                ,--------|  idle  |--------.
    #               /         |        |         \
    #              v          +--------+          v
    #       +----------+          |           +----------+
    #       |          |          | send H/   |          |
    # ,-----| reserved |          | recv H    | reserved |-----.
    # |     | (local)  |          |           | (remote) |     |
    # |     +----------+          v           +----------+     |
    # |         |             +--------+             |         |
    # |         |     recv ES |        | send ES     |         |
    # |  send H |     ,-------|  open  |-------.     | recv H  |
    # |         |    /        |        |        \    |         |
    # |         v   v         +--------+         v   v         |
    # |     +----------+          |           +----------+     |
    # |     |   half   |          |           |   half   |     |
    # |     |  closed  |          | send R/   |  closed  |     |
    # |     | (remote) |          | recv R    | (local)  |     |
    # |     +----------+          |           +----------+     |
    # |          |                |                 |          |
    # |          | send ES/       |        recv ES/ |          |
    # |          | send R/        v         send R/ |          |
    # |          | recv R     +--------+    recv R  |          |
    # | send R/  `----------->|        |<-----------'  send R/ |
    # | recv R                | closed |               recv R  |
    # `---------------------->|        |<----------------------'
    #                         +--------+
    #
    def transition(frame, sending)
      case @state

      # All streams start in the "idle" state.  In this state, no frames
      # have been exchanged.
      # The following transitions are valid from this state:
      # *  Sending or receiving a HEADERS frame causes the stream to
      #    become "open".  The stream identifier is selected as described
      #    in Section 5.1.1.  The same HEADERS frame can also cause a
      #    stream to immediately become "half closed".
      # *  Sending a PUSH_PROMISE frame reserves an idle stream for later
      #    use.  The stream state for the reserved stream transitions to
      #    "reserved (local)".
      # *  Receiving a PUSH_PROMISE frame reserves an idle stream for
      #    later use.  The stream state for the reserved stream
      #    transitions to "reserved (remote)".
      # Receiving any frames other than HEADERS, PUSH_PROMISE or PRIORITY
      # on a stream in this state MUST be treated as a connection error
      # (Section 5.4.1) of type PROTOCOL_ERROR.

      when :idle
        if sending
          case frame[:type]
          when :push_promise then event(:reserved_local)
          when :headers
            if end_stream?(frame)
              event(:half_closed_local)
            else
              event(:open)
            end
          when :rst_stream then event(:local_rst)
          when :priority then process_priority(frame)
          else stream_error
          end
        else
          case frame[:type]
          when :push_promise then event(:reserved_remote)
          when :headers
            if end_stream?(frame)
              event(:half_closed_remote)
            else
              event(:open)
            end
          when :priority then process_priority(frame)
          else stream_error(:protocol_error)
          end
        end

      # A stream in the "reserved (local)" state is one that has been
      # promised by sending a PUSH_PROMISE frame.  A PUSH_PROMISE frame
      # reserves an idle stream by associating the stream with an open
      # stream that was initiated by the remote peer (see Section 8.2).
      # In this state, only the following transitions are possible:
      # *  The endpoint can send a HEADERS frame.  This causes the stream
      #    to open in a "half closed (remote)" state.
      # *  Either endpoint can send a RST_STREAM frame to cause the stream
      #    to become "closed".  This releases the stream reservation.
      # An endpoint MUST NOT send any type of frame other than HEADERS,
      # RST_STREAM, or PRIORITY in this state.
      # A PRIORITY or WINDOW_UPDATE frame MAY be received in this state.
      # Receiving any type of frame other than RST_STREAM, PRIORITY or
      # WINDOW_UPDATE on a stream in this state MUST be treated as a
      # connection error (Section 5.4.1) of type PROTOCOL_ERROR.
      when :reserved_local
        @state = if sending
          case frame[:type]
          when :headers     then event(:half_closed_remote)
          when :rst_stream  then event(:local_rst)
          else stream_error
          end
        else
          case frame[:type]
          when :rst_stream then event(:remote_rst)
          when :priority, :window_update then @state
          else stream_error
          end
        end

      # A stream in the "reserved (remote)" state has been reserved by a
      # remote peer.
      # In this state, only the following transitions are possible:
      # *  Receiving a HEADERS frame causes the stream to transition to
      #    "half closed (local)".
      # *  Either endpoint can send a RST_STREAM frame to cause the stream
      #    to become "closed".  This releases the stream reservation.
      # An endpoint MAY send a PRIORITY frame in this state to
      # reprioritize the reserved stream.  An endpoint MUST NOT send any
      # type of frame other than RST_STREAM, WINDOW_UPDATE, or PRIORITY in
      # this state.
      # Receiving any type of frame other than HEADERS, RST_STREAM or
      # PRIORITY on a stream in this state MUST be treated as a connection
      # error (Section 5.4.1) of type PROTOCOL_ERROR.
      when :reserved_remote
        @state = if sending
          case frame[:type]
          when :rst_stream then event(:local_rst)
          when :priority, :window_update then @state
          else stream_error
          end
        else
          case frame[:type]
          when :headers then event(:half_closed_local)
          when :rst_stream then event(:remote_rst)
          else stream_error
          end
        end

      # A stream in the "open" state may be used by both peers to send
      # frames of any type.  In this state, sending peers observe
      # advertised stream level flow control limits (Section 5.2).
      # From this state either endpoint can send a frame with an
      # END_STREAM flag set, which causes the stream to transition into
      # one of the "half closed" states: an endpoint sending an END_STREAM
      # flag causes the stream state to become "half closed (local)"; an
      # endpoint receiving an END_STREAM flag causes the stream state to
      # become "half closed (remote)".
      # Either endpoint can send a RST_STREAM frame from this state,
      # causing it to transition immediately to "closed".
      when :open
        if sending
          case frame[:type]
          when :data, :headers, :continuation
            event(:half_closed_local) if end_stream?(frame)
          when :rst_stream then event(:local_rst)
          end
        else
          case frame[:type]
          when :data, :headers, :continuation
            event(:half_closed_remote) if end_stream?(frame)
          when :rst_stream then event(:remote_rst)
          end
        end

      # A stream that is in the "half closed (local)" state cannot be used
      # for sending frames.  Only WINDOW_UPDATE, PRIORITY and RST_STREAM
      # frames can be sent in this state.
      # A stream transitions from this state to "closed" when a frame that
      # contains an END_STREAM flag is received, or when either peer sends
      # a RST_STREAM frame.
      # A receiver can ignore WINDOW_UPDATE frames in this state, which
      # might arrive for a short period after a frame bearing the
      # END_STREAM flag is sent.
      # PRIORITY frames received in this state are used to reprioritize
      # streams that depend on the current stream.
      when :half_closed_local
        if sending
          case frame[:type]
          when :rst_stream
            event(:local_rst)
          when :priority
            process_priority(frame)
          when :window_update
            # nop here
          else
            stream_error
          end
        else
          case frame[:type]
          when :data, :headers, :continuation
            event(:remote_closed) if end_stream?(frame)
          when :rst_stream then event(:remote_rst)
          when :priority
            process_priority(frame)
          when :window_update
            # nop here
          end
        end

      # A stream that is "half closed (remote)" is no longer being used by
      # the peer to send frames.  In this state, an endpoint is no longer
      # obligated to maintain a receiver flow control window if it
      # performs flow control.
      # If an endpoint receives additional frames for a stream that is in
      # this state, other than WINDOW_UPDATE, PRIORITY or RST_STREAM, it
      # MUST respond with a stream error (Section 5.4.2) of type
      # STREAM_CLOSED.
      # A stream that is "half closed (remote)" can be used by the
      # endpoint to send frames of any type.  In this state, the endpoint
      # continues to observe advertised stream level flow control limits
      # (Section 5.2).
      # A stream can transition from this state to "closed" by sending a
      # frame that contains an END_STREAM flag, or when either peer sends
      # a RST_STREAM frame.
      when :half_closed_remote
        if sending
          case frame[:type]
          when :data, :headers, :continuation
            event(:local_closed) if end_stream?(frame)
          when :rst_stream then event(:local_rst)
          end
        else
          case frame[:type]
          when :rst_stream then event(:remote_rst)
          when :priority
            process_priority(frame)
          when :window_update
            # nop
          else
            stream_error(:stream_closed)
          end
        end

      # The "closed" state is the terminal state.
      # An endpoint MUST NOT send frames other than PRIORITY on a closed
      # stream.  An endpoint that receives any frame other than PRIORITY
      # after receiving a RST_STREAM MUST treat that as a stream error
      # (Section 5.4.2) of type STREAM_CLOSED.  Similarly, an endpoint
      # that receives any frames after receiving a frame with the
      # END_STREAM flag set MUST treat that as a connection error
      # (Section 5.4.1) of type STREAM_CLOSED, unless the frame is
      # permitted as described below.
      # WINDOW_UPDATE or RST_STREAM frames can be received in this state
      # for a short period after a DATA or HEADERS frame containing an
      # END_STREAM flag is sent.  Until the remote peer receives and
      # processes RST_STREAM or the frame bearing the END_STREAM flag, it
      # might send frames of these types.  Endpoints MUST ignore
      # WINDOW_UPDATE or RST_STREAM frames received in this state, though
      # endpoints MAY choose to treat frames that arrive a significant
      # time after sending END_STREAM as a connection error
      # (Section 5.4.1) of type PROTOCOL_ERROR.
      # PRIORITY frames can be sent on closed streams to prioritize
      # streams that are dependent on the closed stream.  Endpoints SHOULD
      # process PRIORITY frames, though they can be ignored if the stream
      # has been removed from the dependency tree (see Section 5.3.4).
      # If this state is reached as a result of sending a RST_STREAM
      # frame, the peer that receives the RST_STREAM might have already
      # sent - or enqueued for sending - frames on the stream that cannot
      # be withdrawn.  An endpoint MUST ignore frames that it receives on
      # closed streams after it has sent a RST_STREAM frame.  An endpoint
      # MAY choose to limit the period over which it ignores frames and
      # treat frames that arrive after this time as being in error.
      # Flow controlled frames (i.e., DATA) received after sending
      # RST_STREAM are counted toward the connection flow control window.
      # Even though these frames might be ignored, because they are sent
      # before the sender receives the RST_STREAM, the sender will
      # consider the frames to count against the flow control window.
      # An endpoint might receive a PUSH_PROMISE frame after it sends
      # RST_STREAM.  PUSH_PROMISE causes a stream to become "reserved"
      # even if the associated stream has been reset.  Therefore, a
      # RST_STREAM is needed to close an unwanted promised stream.
      when :closed
        if sending
          case frame[:type]
          when :rst_stream then # ignore
          when :priority   then
            process_priority(frame)
          else
            stream_error(:stream_closed) unless (frame[:type] == :rst_stream)
          end
        else
          if frame[:type] == :priority
            process_priority(frame)
          else
            case @closed
            when :remote_rst, :remote_closed
              case frame[:type]
              when :rst_stream, :window_update # nop here
              else
                stream_error(:stream_closed)
              end
            when :local_rst, :local_closed
              frame[:ignore] = true if frame[:type] != :window_update
            end
          end
        end
      end
    end

    def event(newstate)
      case newstate
      when :open
        @state = newstate
        emit(:active)

      when :reserved_local, :reserved_remote
        @state = newstate
        emit(:reserved)

      when :half_closed_local, :half_closed_remote
        @closed = newstate
        emit(:active) unless @state == :open
        @state = :half_closing

      when :local_closed, :remote_closed, :local_rst, :remote_rst
        @closed = newstate
        @state  = :closing
      end

      @state
    end

    def complete_transition(frame)
      case @state
      when :closing
        @state = :closed
        emit(:close, frame[:error])
      when :half_closing
        @state = @closed
        emit(:half_close)
      end
    end

    def process_priority(frame)
      @weight = frame[:weight]
      @dependency = frame[:stream_dependency]
      emit(
        :priority,
        weight:     frame[:weight],
        dependency: frame[:stream_dependency],
        exclusive:  frame[:exclusive],
      )
      # TODO: implement dependency tree housekeeping
      #   Latest draft defines a fairly complex priority control.
      #   See https://tools.ietf.org/html/draft-ietf-httpbis-http2-16#section-5.3
      #   We currently have no prioritization among streams.
      #   We should add code here.
    end

    def end_stream?(frame)
      case frame[:type]
      when :data, :headers, :continuation
        frame[:flags].include?(:end_stream)
      else false
      end
    end

    def stream_error(error = :internal_error, msg: nil)
      @error = error
      close(error) if @state != :closed

      klass = error.to_s.split('_').map(&:capitalize).join
      fail Error.const_get(klass), msg
    end
    alias error stream_error

    def manage_state(frame)
      transition(frame, true)
      frame[:stream] ||= @id
      yield
      complete_transition(frame)
    end
  end
end
