module HTTP2
  # Performs encoding, decoding, and validation of binary HTTP/2 frames.
  #
  # rubocop:disable ClassLength
  class Framer
    include Error

    # Default value of max frame size (16384 bytes)
    DEFAULT_MAX_FRAME_SIZE = 2**14

    # Current maximum frame size
    attr_accessor :max_frame_size

    # Maximum stream ID (2^31)
    MAX_STREAM_ID = 0x7fffffff

    # Maximum window increment value (2^31)
    MAX_WINDOWINC = 0x7fffffff

    # HTTP/2 frame type mapping as defined by the spec
    FRAME_TYPES = {
      data:          0x0,
      headers:       0x1,
      priority:      0x2,
      rst_stream:    0x3,
      settings:      0x4,
      push_promise:  0x5,
      ping:          0x6,
      goaway:        0x7,
      window_update: 0x8,
      continuation:  0x9,
      altsvc:        0xa,
    }.freeze

    FRAME_TYPES_WITH_PADDING = [:data, :headers, :push_promise].freeze

    # Per frame flags as defined by the spec
    FRAME_FLAGS = {
      data: {
        end_stream:  0,
        padded: 3,
        compressed: 5,
      },
      headers: {
        end_stream:  0,
        end_headers: 2,
        padded: 3,
        priority: 5,
      },
      priority:     {},
      rst_stream:   {},
      settings:     { ack: 0 },
      push_promise: {
        end_headers: 2,
        padded: 3,
      },
      ping:         { ack: 0 },
      goaway:       {},
      window_update: {},
      continuation: { end_headers: 2 },
      altsvc: {},
    }.each_value(&:freeze).freeze

    # Default settings as defined by the spec
    DEFINED_SETTINGS = {
      settings_header_table_size:      1,
      settings_enable_push:            2,
      settings_max_concurrent_streams: 3,
      settings_initial_window_size:    4,
      settings_max_frame_size:         5,
      settings_max_header_list_size:   6,
    }.freeze

    # Default error types as defined by the spec
    DEFINED_ERRORS = {
      no_error:           0,
      protocol_error:     1,
      internal_error:     2,
      flow_control_error: 3,
      settings_timeout:   4,
      stream_closed:      5,
      frame_size_error:   6,
      refused_stream:     7,
      cancel:             8,
      compression_error:  9,
      connect_error:      10,
      enhance_your_calm:  11,
      inadequate_security: 12,
      http_1_1_required:  13,
    }.freeze

    RBIT  = 0x7fffffff
    RBYTE = 0x0fffffff
    EBIT  = 0x80000000
    UINT32 = 'N'.freeze
    UINT16 = 'n'.freeze
    UINT8  = 'C'.freeze
    HEADERPACK = (UINT8 + UINT16 + UINT8 + UINT8 + UINT32).freeze
    FRAME_LENGTH_HISHIFT = 16
    FRAME_LENGTH_LOMASK  = 0xFFFF

    private_constant :RBIT, :RBYTE, :EBIT, :HEADERPACK, :UINT32, :UINT16, :UINT8

    # Initializes new framer object.
    #
    def initialize
      @max_frame_size = DEFAULT_MAX_FRAME_SIZE
    end

    # Generates common 9-byte frame header.
    # - http://tools.ietf.org/html/draft-ietf-httpbis-http2-16#section-4.1
    #
    # @param frame [Hash]
    # @return [String]
    def common_header(frame)
      header = []

      unless FRAME_TYPES[frame[:type]]
        fail CompressionError, "Invalid frame type (#{frame[:type]})"
      end

      if frame[:length] > @max_frame_size
        fail CompressionError, "Frame size is too large: #{frame[:length]}"
      end

      if frame[:length] < 0
        fail CompressionError, "Frame size is invalid: #{frame[:length]}"
      end

      if frame[:stream] > MAX_STREAM_ID
        fail CompressionError, "Stream ID (#{frame[:stream]}) is too large"
      end

      if frame[:type] == :window_update && frame[:increment] > MAX_WINDOWINC
        fail CompressionError, "Window increment (#{frame[:increment]}) is too large"
      end

      header << (frame[:length] >> FRAME_LENGTH_HISHIFT)
      header << (frame[:length] & FRAME_LENGTH_LOMASK)
      header << FRAME_TYPES[frame[:type]]
      header << frame[:flags].reduce(0) do |acc, f|
        position = FRAME_FLAGS[frame[:type]][f]
        unless position
          fail CompressionError, "Invalid frame flag (#{f}) for #{frame[:type]}"
        end

        acc | (1 << position)
      end

      header << frame[:stream]
      header.pack(HEADERPACK) # 8+16,8,8,32
    end

    # Decodes common 9-byte header.
    #
    # @param buf [Buffer]
    def read_common_header(buf)
      frame = {}
      len_hi, len_lo, type, flags, stream = buf.slice(0, 9).unpack(HEADERPACK)

      frame[:length] = (len_hi << FRAME_LENGTH_HISHIFT) | len_lo
      frame[:type], _ = FRAME_TYPES.find { |_t, pos| type == pos }
      if frame[:type]
        frame[:flags] = FRAME_FLAGS[frame[:type]].each_with_object([]) do |(name, pos), acc|
          acc << name if (flags & (1 << pos)) > 0
        end
      end

      frame[:stream] = stream & RBIT
      frame
    end

    # Generates encoded HTTP/2 frame.
    # - http://tools.ietf.org/html/draft-ietf-httpbis-http2
    #
    # @param frame [Hash]
    def generate(frame)
      bytes  = Buffer.new
      length = 0

      frame[:flags] ||= []
      frame[:stream] ||= 0

      case frame[:type]
      when :data
        bytes << frame[:payload]
        length += frame[:payload].bytesize

      when :headers
        if frame[:weight] || frame[:stream_dependency] || !frame[:exclusive].nil?
          unless frame[:weight] && frame[:stream_dependency] && !frame[:exclusive].nil?
            fail CompressionError, "Must specify all of priority parameters for #{frame[:type]}"
          end
          frame[:flags] += [:priority] unless frame[:flags].include? :priority
        end

        if frame[:flags].include? :priority
          bytes << [(frame[:exclusive] ? EBIT : 0) | (frame[:stream_dependency] & RBIT)].pack(UINT32)
          bytes << [frame[:weight] - 1].pack(UINT8)
          length += 5
        end

        bytes << frame[:payload]
        length += frame[:payload].bytesize

      when :priority
        unless frame[:weight] && frame[:stream_dependency] && !frame[:exclusive].nil?
          fail CompressionError, "Must specify all of priority parameters for #{frame[:type]}"
        end
        bytes << [(frame[:exclusive] ? EBIT : 0) | (frame[:stream_dependency] & RBIT)].pack(UINT32)
        bytes << [frame[:weight] - 1].pack(UINT8)
        length += 5

      when :rst_stream
        bytes << pack_error(frame[:error])
        length += 4

      when :settings
        if (frame[:stream]).nonzero?
          fail CompressionError, "Invalid stream ID (#{frame[:stream]})"
        end

        frame[:payload].each do |(k, v)|
          if k.is_a? Integer
            DEFINED_SETTINGS.value?(k) || next
          else
            k = DEFINED_SETTINGS[k]

            fail CompressionError, "Unknown settings ID for #{k}" if k.nil?
          end

          bytes << [k].pack(UINT16)
          bytes << [v].pack(UINT32)
          length += 6
        end

      when :push_promise
        bytes << [frame[:promise_stream] & RBIT].pack(UINT32)
        bytes << frame[:payload]
        length += 4 + frame[:payload].bytesize

      when :ping
        if frame[:payload].bytesize != 8
          fail CompressionError, "Invalid payload size (#{frame[:payload].size} != 8 bytes)"
        end
        bytes << frame[:payload]
        length += 8

      when :goaway
        bytes << [frame[:last_stream] & RBIT].pack(UINT32)
        bytes << pack_error(frame[:error])
        length += 8

        if frame[:payload]
          bytes << frame[:payload]
          length += frame[:payload].bytesize
        end

      when :window_update
        bytes << [frame[:increment] & RBIT].pack(UINT32)
        length += 4

      when :continuation
        bytes << frame[:payload]
        length += frame[:payload].bytesize

      when :altsvc
        bytes << [frame[:max_age], frame[:port]].pack(UINT32 + UINT16)
        length += 6
        if frame[:proto]
          fail CompressionError, 'Proto too long' if frame[:proto].bytesize > 255
          bytes << [frame[:proto].bytesize].pack(UINT8)
          bytes << frame[:proto].force_encoding(Encoding::BINARY)
          length += 1 + frame[:proto].bytesize
        else
          bytes << [0].pack(UINT8)
          length += 1
        end
        if frame[:host]
          fail CompressionError, 'Host too long' if frame[:host].bytesize > 255
          bytes << [frame[:host].bytesize].pack(UINT8)
          bytes << frame[:host].force_encoding(Encoding::BINARY)
          length += 1 + frame[:host].bytesize
        else
          bytes << [0].pack(UINT8)
          length += 1
        end
        if frame[:origin]
          bytes << frame[:origin]
          length += frame[:origin].bytesize
        end
      end

      # Process padding.
      #  frame[:padding] gives number of extra octets to be added.
      # - http://tools.ietf.org/html/draft-ietf-httpbis-http2-16#section-6.1
      if frame[:padding]
        unless FRAME_TYPES_WITH_PADDING.include?(frame[:type])
          fail CompressionError, "Invalid padding flag for #{frame[:type]}"
        end

        padlen = frame[:padding]

        if padlen <= 0 || padlen > 256 || padlen + length > @max_frame_size
          fail CompressionError, "Invalid padding #{padlen}"
        end

        length += padlen
        bytes.prepend([padlen -= 1].pack(UINT8))
        frame[:flags] << :padded

        # Padding:  Padding octets that contain no application semantic value.
        # Padding octets MUST be set to zero when sending and ignored when
        # receiving.
        bytes << "\0" * padlen
      end

      frame[:length] = length
      bytes.prepend(common_header(frame))
    end

    # Decodes complete HTTP/2 frame from provided buffer. If the buffer
    # does not contain enough data, no further work is performed.
    #
    # @param buf [Buffer]
    def parse(buf)
      return nil if buf.size < 9
      frame = read_common_header(buf)
      return nil if buf.size < 9 + frame[:length]

      fail ProtocolError, 'payload too large' if frame[:length] > DEFAULT_MAX_FRAME_SIZE

      buf.read(9)
      payload = buf.read(frame[:length])

      # Implementations MUST discard frames
      # that have unknown or unsupported types.
      # - http://tools.ietf.org/html/draft-ietf-httpbis-http2-16#section-5.5
      return nil if frame[:type].nil?

      # Process padding
      padlen = 0
      if FRAME_TYPES_WITH_PADDING.include?(frame[:type])
        padded = frame[:flags].include?(:padded)
        if padded
          padlen = payload.read(1).unpack(UINT8).first
          frame[:padding] = padlen + 1
          fail ProtocolError, 'padding too long' if padlen > payload.bytesize
          payload.slice!(-padlen, padlen) if padlen > 0
          frame[:length] -= frame[:padding]
          frame[:flags].delete(:padded)
        end
      end

      case frame[:type]
      when :data
        frame[:payload] = payload.read(frame[:length])
      when :headers
        if frame[:flags].include? :priority
          e_sd = payload.read_uint32
          frame[:stream_dependency] = e_sd & RBIT
          frame[:exclusive] = (e_sd & EBIT) != 0
          frame[:weight] = payload.getbyte + 1
        end
        frame[:payload] = payload.read(frame[:length])
      when :priority
        e_sd = payload.read_uint32
        frame[:stream_dependency] = e_sd & RBIT
        frame[:exclusive] = (e_sd & EBIT) != 0
        frame[:weight] = payload.getbyte + 1
      when :rst_stream
        frame[:error] = unpack_error payload.read_uint32

      when :settings
        # NOTE: frame[:length] might not match the number of frame[:payload]
        # because unknown extensions are ignored.
        frame[:payload] = []
        unless (frame[:length] % 6).zero?
          fail ProtocolError, 'Invalid settings payload length'
        end

        if (frame[:stream]).nonzero?
          fail ProtocolError, "Invalid stream ID (#{frame[:stream]})"
        end

        (frame[:length] / 6).times do
          id  = payload.read(2).unpack(UINT16).first
          val = payload.read_uint32

          # Unsupported or unrecognized settings MUST be ignored.
          # Here we send it along.
          name, _ = DEFINED_SETTINGS.find { |_name, v| v == id }
          frame[:payload] << [name, val] if name
        end
      when :push_promise
        frame[:promise_stream] = payload.read_uint32 & RBIT
        frame[:payload] = payload.read(frame[:length])
      when :ping
        frame[:payload] = payload.read(frame[:length])
      when :goaway
        frame[:last_stream] = payload.read_uint32 & RBIT
        frame[:error] = unpack_error payload.read_uint32

        size = frame[:length] - 8 # for last_stream and error
        frame[:payload] = payload.read(size) if size > 0
      when :window_update
        frame[:increment] = payload.read_uint32 & RBIT
      when :continuation
        frame[:payload] = payload.read(frame[:length])
      when :altsvc
        frame[:max_age], frame[:port] = payload.read(6).unpack(UINT32 + UINT16)

        len = payload.getbyte
        frame[:proto] = payload.read(len) if len > 0

        len = payload.getbyte
        frame[:host] = payload.read(len) if len > 0

        frame[:origin] = payload.read(payload.size) if payload.size > 0
        # else # Unknown frame type is explicitly allowed
      end

      frame
    end

    private

    def pack_error(e)
      unless e.is_a? Integer
        if DEFINED_ERRORS[e].nil?
          fail CompressionError, "Unknown error ID for #{e}"
        end

        e = DEFINED_ERRORS[e]
      end

      [e].pack(UINT32)
    end

    def unpack_error(e)
      name, _ = DEFINED_ERRORS.find { |_name, v| v == e }
      name || error
    end
  end
  # rubocop:enable ClassLength
end
