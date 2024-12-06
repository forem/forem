require 'forwardable'

module HTTP2
  # Binary buffer wraps String.
  #
  class Buffer
    extend Forwardable

    def_delegators :@buffer, :ord, :encoding, :setbyte, :unpack,
                   :size, :each_byte, :to_str, :to_s, :length, :inspect,
                   :[], :[]=, :empty?, :bytesize, :include?

    UINT32 = 'N'.freeze
    private_constant :UINT32

    # Forces binary encoding on the string
    def initialize(str = '')
      str = str.dup if str.frozen?
      @buffer = str.force_encoding(Encoding::BINARY)
    end

    # Emulate StringIO#read: slice first n bytes from the buffer.
    #
    # @param n [Integer] number of bytes to slice from the buffer
    def read(n)
      Buffer.new(@buffer.slice!(0, n))
    end

    # Emulate StringIO#getbyte: slice first byte from buffer.
    def getbyte
      read(1).ord
    end

    def slice!(*args)
      Buffer.new(@buffer.slice!(*args))
    end

    def slice(*args)
      Buffer.new(@buffer.slice(*args))
    end

    def force_encoding(*args)
      @buffer = @buffer.force_encoding(*args)
    end

    def ==(other)
      @buffer == other
    end

    def +(other)
      @buffer += other
    end

    # Emulate String#getbyte: return nth byte from buffer.
    def readbyte(n)
      @buffer[n].ord
    end

    # Slice unsigned 32-bit integer from buffer.
    # @return [Integer]
    def read_uint32
      read(4).unpack(UINT32).first
    end

    # Ensures that data that is added is binary encoded as well,
    # otherwise this could lead to the Buffer instance changing its encoding.
    [:<<, :prepend].each do |mutating_method|
      define_method(mutating_method) do |string|
        string = string.dup if string.frozen?
        @buffer.send mutating_method, string.force_encoding(Encoding::BINARY)

        self
      end
    end
  end
end
