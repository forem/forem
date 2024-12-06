module Zip
  class DecryptedIo #:nodoc:all
    CHUNK_SIZE = 32_768

    def initialize(io, decrypter)
      @io = io
      @decrypter = decrypter
    end

    def read(length = nil, outbuf = +'')
      return (length.nil? || length.zero? ? '' : nil) if eof

      while length.nil? || (buffer.bytesize < length)
        break if input_finished?

        buffer << produce_input
      end

      outbuf.replace(buffer.slice!(0...(length || output_buffer.bytesize)))
    end

    private

    def eof
      buffer.empty? && input_finished?
    end

    def buffer
      @buffer ||= +''
    end

    def input_finished?
      @io.eof
    end

    def produce_input
      @decrypter.decrypt(@io.read(CHUNK_SIZE))
    end
  end
end
