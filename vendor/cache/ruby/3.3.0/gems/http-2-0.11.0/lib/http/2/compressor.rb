module HTTP2
  # Implementation of header compression for HTTP 2.0 (HPACK) format adapted
  # to efficiently represent HTTP headers in the context of HTTP 2.0.
  #
  # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10
  module Header
    # To decompress header blocks, a decoder only needs to maintain a
    # dynamic table as a decoding context.
    # No other state information is needed.
    class EncodingContext
      include Error

      # @private
      # Static table
      # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#appendix-A
      STATIC_TABLE = [
        [':authority',                  ''],
        [':method',                     'GET'],
        [':method',                     'POST'],
        [':path',                       '/'],
        [':path',                       '/index.html'],
        [':scheme',                     'http'],
        [':scheme',                     'https'],
        [':status',                     '200'],
        [':status',                     '204'],
        [':status',                     '206'],
        [':status',                     '304'],
        [':status',                     '400'],
        [':status',                     '404'],
        [':status',                     '500'],
        ['accept-charset',              ''],
        ['accept-encoding',             'gzip, deflate'],
        ['accept-language',             ''],
        ['accept-ranges',               ''],
        ['accept',                      ''],
        ['access-control-allow-origin', ''],
        ['age',                         ''],
        ['allow',                       ''],
        ['authorization',               ''],
        ['cache-control',               ''],
        ['content-disposition',         ''],
        ['content-encoding',            ''],
        ['content-language',            ''],
        ['content-length',              ''],
        ['content-location',            ''],
        ['content-range',               ''],
        ['content-type',                ''],
        ['cookie',                      ''],
        ['date',                        ''],
        ['etag',                        ''],
        ['expect',                      ''],
        ['expires',                     ''],
        ['from',                        ''],
        ['host',                        ''],
        ['if-match',                    ''],
        ['if-modified-since',           ''],
        ['if-none-match',               ''],
        ['if-range',                    ''],
        ['if-unmodified-since',         ''],
        ['last-modified',               ''],
        ['link',                        ''],
        ['location',                    ''],
        ['max-forwards',                ''],
        ['proxy-authenticate',          ''],
        ['proxy-authorization',         ''],
        ['range',                       ''],
        ['referer',                     ''],
        ['refresh',                     ''],
        ['retry-after',                 ''],
        ['server',                      ''],
        ['set-cookie',                  ''],
        ['strict-transport-security',   ''],
        ['transfer-encoding',           ''],
        ['user-agent',                  ''],
        ['vary',                        ''],
        ['via',                         ''],
        ['www-authenticate',            ''],
      ].each { |pair| pair.each(&:freeze).freeze }.freeze

      # Current table of header key-value pairs.
      attr_reader :table

      # Current encoding options
      #
      #   :table_size  Integer  maximum dynamic table size in bytes
      #   :huffman     Symbol   :always, :never, :shorter
      #   :index       Symbol   :all, :static, :never
      attr_reader :options

      # Initializes compression context with appropriate client/server
      # defaults and maximum size of the dynamic table.
      #
      # @param options [Hash] encoding options
      #   :table_size  Integer  maximum dynamic table size in bytes
      #   :huffman     Symbol   :always, :never, :shorter
      #   :index       Symbol   :all, :static, :never
      def initialize(**options)
        default_options = {
          huffman:    :shorter,
          index:      :all,
          table_size: 4096,
        }
        @table = []
        @options = default_options.merge(options)
        @limit = @options[:table_size]
      end

      # Duplicates current compression context
      # @return [EncodingContext]
      def dup
        other = EncodingContext.new(@options)
        t = @table
        l = @limit
        other.instance_eval do
          @table = t.dup              # shallow copy
          @limit = l
        end
        other
      end

      # Finds an entry in current dynamic table by index.
      # Note that index is zero-based in this module.
      #
      # If the index is greater than the last index in the static table,
      # an entry in the dynamic table is dereferenced.
      #
      # If the index is greater than the last header index, an error is raised.
      #
      # @param index [Integer] zero-based index in the dynamic table.
      # @return [Array] +[key, value]+
      def dereference(index)
        # NOTE: index is zero-based in this module.
        value = STATIC_TABLE[index] || @table[index - STATIC_TABLE.size]
        fail CompressionError, 'Index too large' unless value
        value
      end

      # Header Block Processing
      # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-4.1
      #
      # @param cmd [Hash] { type:, name:, value:, index: }
      # @return [Array, nil] +[name, value]+ header field that is added to the decoded header list,
      #                                      or nil if +cmd[:type]+ is +:changetablesize+
      def process(cmd)
        emit = nil

        case cmd[:type]
        when :changetablesize
          if cmd[:value] > @limit
            fail CompressionError, 'dynamic table size update exceed limit'
          end
          self.table_size = cmd[:value]

        when :indexed
          # Indexed Representation
          # An _indexed representation_ entails the following actions:
          # o  The header field corresponding to the referenced entry in either
          # the static table or dynamic table is added to the decoded header
          # list.
          idx = cmd[:name]

          k, v = dereference(idx)
          emit = [k, v]

        when :incremental, :noindex, :neverindexed
          # A _literal representation_ that is _not added_ to the dynamic table
          # entails the following action:
          # o  The header field is added to the decoded header list.

          # A _literal representation_ that is _added_ to the dynamic table
          # entails the following actions:
          # o  The header field is added to the decoded header list.
          # o  The header field is inserted at the beginning of the dynamic table.

          if cmd[:name].is_a? Integer
            k, v = dereference(cmd[:name])

            cmd = cmd.dup
            cmd[:index] ||= cmd[:name]
            cmd[:value] ||= v
            cmd[:name] = k
          end

          emit = [cmd[:name], cmd[:value]]

          add_to_table(emit) if cmd[:type] == :incremental

        else
          fail CompressionError, "Invalid type: #{cmd[:type]}"
        end

        emit
      end

      # Plan header compression according to +@options [:index]+
      #  :never   Do not use dynamic table or static table reference at all.
      #  :static  Use static table only.
      #  :all     Use all of them.
      #
      # @param headers [Array] +[[name, value], ...]+
      # @return [Array] array of commands
      def encode(headers)
        commands = []
        # Literals commands are marked with :noindex when index is not used
        noindex = [:static, :never].include?(@options[:index])
        headers.each do |field, value|
          # Literal header names MUST be translated to lowercase before
          # encoding and transmission.
          field = field.downcase
          value = '/' if field == ':path' && value.empty?
          cmd = addcmd(field, value)
          cmd[:type] = :noindex if noindex && cmd[:type] == :incremental
          commands << cmd
          process(cmd)
        end
        commands
      end

      # Emits command for a header.
      # Prefer static table over dynamic table.
      # Prefer exact match over name-only match.
      #
      # +@options [:index]+ controls whether to use the dynamic table,
      # static table, or both.
      #  :never   Do not use dynamic table or static table reference at all.
      #  :static  Use static table only.
      #  :all     Use all of them.
      #
      # @param header [Array] +[name, value]+
      # @return [Hash] command
      def addcmd(*header)
        exact = nil
        name_only = nil

        if [:all, :static].include?(@options[:index])
          STATIC_TABLE.each_index do |i|
            if STATIC_TABLE[i] == header
              exact ||= i
              break
            elsif STATIC_TABLE[i].first == header.first
              name_only ||= i
            end
          end
        end
        if [:all].include?(@options[:index]) && !exact
          @table.each_index do |i|
            if @table[i] == header
              exact ||= i + STATIC_TABLE.size
              break
            elsif @table[i].first == header.first
              name_only ||= i + STATIC_TABLE.size
            end
          end
        end

        if exact
          { name: exact, type: :indexed }
        elsif name_only
          { name: name_only, value: header.last, type: :incremental }
        else
          { name: header.first, value: header.last, type: :incremental }
        end
      end

      # Alter dynamic table size.
      #  When the size is reduced, some headers might be evicted.
      def table_size=(size)
        @limit = size
        size_check(nil)
      end

      # Returns current table size in octets
      # @return [Integer]
      def current_table_size
        @table.inject(0) { |r, (k, v)| r + k.bytesize + v.bytesize + 32 }
      end

      private

      # Add a name-value pair to the dynamic table.
      # Older entries might have been evicted so that
      # the new entry fits in the dynamic table.
      #
      # @param cmd [Array] +[name, value]+
      def add_to_table(cmd)
        return unless size_check(cmd)
        @table.unshift(cmd)
      end

      # To keep the dynamic table size lower than or equal to @limit,
      # remove one or more entries at the end of the dynamic table.
      #
      # @param cmd [Hash]
      # @return [Boolean] whether +cmd+ fits in the dynamic table.
      def size_check(cmd)
        cursize = current_table_size
        cmdsize = cmd.nil? ? 0 : cmd[0].bytesize + cmd[1].bytesize + 32

        while cursize + cmdsize > @limit
          break if @table.empty?

          e = @table.pop
          cursize -= e[0].bytesize + e[1].bytesize + 32
        end

        cmdsize <= @limit
      end
    end

    # Header representation as defined by the spec.
    HEADREP = {
      indexed:      { prefix: 7, pattern: 0x80 },
      incremental:  { prefix: 6, pattern: 0x40 },
      noindex:      { prefix: 4, pattern: 0x00 },
      neverindexed: { prefix: 4, pattern: 0x10 },
      changetablesize: { prefix: 5, pattern: 0x20 },
    }.each_value(&:freeze).freeze

    # Predefined options set for Compressor
    # http://mew.org/~kazu/material/2014-hpack.pdf
    NAIVE    = { index: :never,  huffman: :never   }.freeze
    LINEAR   = { index: :all,    huffman: :never   }.freeze
    STATIC   = { index: :static, huffman: :never   }.freeze
    SHORTER  = { index: :all,    huffman: :never   }.freeze
    NAIVEH   = { index: :never,  huffman: :always  }.freeze
    LINEARH  = { index: :all,    huffman: :always  }.freeze
    STATICH  = { index: :static, huffman: :always  }.freeze
    SHORTERH = { index: :all,    huffman: :shorter }.freeze

    # Responsible for encoding header key-value pairs using HPACK algorithm.
    class Compressor
      # @param options [Hash] encoding options
      def initialize(**options)
        @cc = EncodingContext.new(**options)
      end

      # Set dynamic table size in EncodingContext
      # @param size [Integer] new dynamic table size
      def table_size=(size)
        @cc.table_size = size
      end

      # Encodes provided value via integer representation.
      # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-5.1
      #
      #  If I < 2^N - 1, encode I on N bits
      #  Else
      #      encode 2^N - 1 on N bits
      #      I = I - (2^N - 1)
      #      While I >= 128
      #           Encode (I % 128 + 128) on 8 bits
      #           I = I / 128
      #      encode (I) on 8 bits
      #
      # @param i [Integer] value to encode
      # @param n [Integer] number of available bits
      # @return [String] binary string
      def integer(i, n)
        limit = 2**n - 1
        return [i].pack('C') if i < limit

        bytes = []
        bytes.push limit unless n.zero?

        i -= limit
        while (i >= 128)
          bytes.push((i % 128) + 128)
          i /= 128
        end

        bytes.push i
        bytes.pack('C*')
      end

      # Encodes provided value via string literal representation.
      # - http://tools.ietf.org/html/draft-ietf-httpbis-header-compression-10#section-5.2
      #
      # * The string length, defined as the number of bytes needed to store
      #   its UTF-8 representation, is represented as an integer with a seven
      #   bits prefix. If the string length is strictly less than 127, it is
      #   represented as one byte.
      # * If the bit 7 of the first byte is 1, the string value is represented
      #   as a list of Huffman encoded octets
      #   (padded with bit 1's until next octet boundary).
      # * If the bit 7 of the first byte is 0, the string value is
      #   represented as a list of UTF-8 encoded octets.
      #
      # +@options [:huffman]+ controls whether to use Huffman encoding:
      #  :never   Do not use Huffman encoding
      #  :always  Always use Huffman encoding
      #  :shorter Use Huffman when the result is strictly shorter
      #
      # @param str [String]
      # @return [String] binary string
      def string(str)
        plain, huffman = nil, nil
        unless @cc.options[:huffman] == :always
          plain = integer(str.bytesize, 7) << str.dup.force_encoding(Encoding::BINARY)
        end
        unless @cc.options[:huffman] == :never
          huffman = Huffman.new.encode(str)
          huffman = integer(huffman.bytesize, 7) << huffman
          huffman.setbyte(0, huffman.ord | 0x80)
        end
        case @cc.options[:huffman]
        when :always
          huffman
        when :never
          plain
        else
          huffman.bytesize < plain.bytesize ? huffman : plain
        end
      end

      # Encodes header command with appropriate header representation.
      #
      # @param h [Hash] header command
      # @param buffer [String]
      # @return [Buffer]
      def header(h, buffer = Buffer.new)
        rep = HEADREP[h[:type]]

        case h[:type]
        when :indexed
          buffer << integer(h[:name] + 1, rep[:prefix])
        when :changetablesize
          buffer << integer(h[:value], rep[:prefix])
        else
          if h[:name].is_a? Integer
            buffer << integer(h[:name] + 1, rep[:prefix])
          else
            buffer << integer(0, rep[:prefix])
            buffer << string(h[:name])
          end

          buffer << string(h[:value])
        end

        # set header representation pattern on first byte
        fb = buffer.ord | rep[:pattern]
        buffer.setbyte(0, fb)

        buffer
      end

      # Encodes provided list of HTTP headers.
      #
      # @param headers [Array] +[[name, value], ...]+
      # @return [Buffer]
      def encode(headers)
        buffer = Buffer.new
        pseudo_headers, regular_headers = headers.partition { |f, _| f.start_with? ':' }
        headers = [*pseudo_headers, *regular_headers]
        commands = @cc.encode(headers)
        commands.each do |cmd|
          buffer << header(cmd)
        end

        buffer
      end
    end

    # Responsible for decoding received headers and maintaining compression
    # context of the opposing peer. Decompressor must be initialized with
    # appropriate starting context based on local role: client or server.
    #
    # @example
    #   server_role = Decompressor.new(:request)
    #   client_role = Decompressor.new(:response)
    class Decompressor
      # @param options [Hash] decoding options.  Only :table_size is effective.
      def initialize(**options)
        @cc = EncodingContext.new(**options)
      end

      # Set dynamic table size in EncodingContext
      # @param size [Integer] new dynamic table size
      def table_size=(size)
        @cc.table_size = size
      end

      # Decodes integer value from provided buffer.
      #
      # @param buf [String]
      # @param n [Integer] number of available bits
      # @return [Integer]
      def integer(buf, n)
        limit = 2**n - 1
        i = !n.zero? ? (buf.getbyte & limit) : 0

        m = 0
        while (byte = buf.getbyte)
          i += ((byte & 127) << m)
          m += 7

          break if (byte & 128).zero?
        end if (i == limit)

        i
      end

      # Decodes string value from provided buffer.
      #
      # @param buf [String]
      # @return [String] UTF-8 encoded string
      # @raise [CompressionError] when input is malformed
      def string(buf)
        huffman = (buf.readbyte(0) & 0x80) == 0x80
        len = integer(buf, 7)
        str = buf.read(len)
        fail CompressionError, 'string too short' unless str.bytesize == len
        str = Huffman.new.decode(Buffer.new(str)) if huffman
        str.force_encoding(Encoding::UTF_8)
      end

      # Decodes header command from provided buffer.
      #
      # @param buf [Buffer]
      # @return [Hash] command
      def header(buf)
        peek = buf.readbyte(0)

        header = {}
        header[:type], type = HEADREP.find do |_t, desc|
          mask = (peek >> desc[:prefix]) << desc[:prefix]
          mask == desc[:pattern]
        end

        fail CompressionError unless header[:type]

        header[:name] = integer(buf, type[:prefix])

        case header[:type]
        when :indexed
          fail CompressionError if (header[:name]).zero?
          header[:name] -= 1
        when :changetablesize
          header[:value] = header[:name]
        else
          if (header[:name]).zero?
            header[:name] = string(buf)
          else
            header[:name] -= 1
          end
          header[:value] = string(buf)
        end

        header
      end

      # Decodes and processes header commands within provided buffer.
      #
      # @param buf [Buffer]
      # @return [Array] +[[name, value], ...]+
      def decode(buf)
        list = []
        decoding_pseudo_headers = true
        until buf.empty?
          next_header = @cc.process(header(buf))
          next if next_header.nil?
          is_pseudo_header = next_header.first.start_with? ':'
          if !decoding_pseudo_headers && is_pseudo_header
            fail ProtocolError, 'one or more pseudo headers encountered after regular headers'
          end
          decoding_pseudo_headers = is_pseudo_header
          list << next_header
        end
        list
      end
    end
  end
end
