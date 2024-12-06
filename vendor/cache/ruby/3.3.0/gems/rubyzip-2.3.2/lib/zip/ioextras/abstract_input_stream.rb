module Zip
  module IOExtras
    # Implements many of the convenience methods of IO
    # such as gets, getc, readline and readlines
    # depends on: input_finished?, produce_input and read
    module AbstractInputStream
      include Enumerable
      include FakeIO

      def initialize
        super
        @lineno        = 0
        @pos           = 0
        @output_buffer = ''
      end

      attr_accessor :lineno
      attr_reader :pos

      def read(number_of_bytes = nil, buf = '')
        tbuf = if @output_buffer.bytesize > 0
                 if number_of_bytes <= @output_buffer.bytesize
                   @output_buffer.slice!(0, number_of_bytes)
                 else
                   number_of_bytes -= @output_buffer.bytesize if number_of_bytes
                   rbuf = sysread(number_of_bytes, buf)
                   out  = @output_buffer
                   out << rbuf if rbuf
                   @output_buffer = ''
                   out
                 end
               else
                 sysread(number_of_bytes, buf)
               end

        if tbuf.nil? || tbuf.empty?
          return nil if number_of_bytes

          return ''
        end

        @pos += tbuf.length

        if buf
          buf.replace(tbuf)
        else
          buf = tbuf
        end
        buf
      end

      def readlines(a_sep_string = $INPUT_RECORD_SEPARATOR)
        ret_val = []
        each_line(a_sep_string) { |line| ret_val << line }
        ret_val
      end

      def gets(a_sep_string = $INPUT_RECORD_SEPARATOR, number_of_bytes = nil)
        @lineno = @lineno.next

        if number_of_bytes.respond_to?(:to_int)
          number_of_bytes = number_of_bytes.to_int
          a_sep_string = a_sep_string.to_str if a_sep_string
        elsif a_sep_string.respond_to?(:to_int)
          number_of_bytes = a_sep_string.to_int
          a_sep_string    = $INPUT_RECORD_SEPARATOR
        else
          number_of_bytes = nil
          a_sep_string = a_sep_string.to_str if a_sep_string
        end

        return read(number_of_bytes) if a_sep_string.nil?

        a_sep_string = "#{$INPUT_RECORD_SEPARATOR}#{$INPUT_RECORD_SEPARATOR}" if a_sep_string.empty?

        buffer_index = 0
        over_limit   = (number_of_bytes && @output_buffer.bytesize >= number_of_bytes)
        while (match_index = @output_buffer.index(a_sep_string, buffer_index)).nil? && !over_limit
          buffer_index = [buffer_index, @output_buffer.bytesize - a_sep_string.bytesize].max
          return @output_buffer.empty? ? nil : flush if input_finished?

          @output_buffer << produce_input
          over_limit = (number_of_bytes && @output_buffer.bytesize >= number_of_bytes)
        end
        sep_index = [match_index + a_sep_string.bytesize, number_of_bytes || @output_buffer.bytesize].min
        @pos += sep_index
        @output_buffer.slice!(0...sep_index)
      end

      def ungetc(byte)
        @output_buffer = byte.chr + @output_buffer
      end

      def flush
        ret_val        = @output_buffer
        @output_buffer = ''
        ret_val
      end

      def readline(a_sep_string = $INPUT_RECORD_SEPARATOR)
        ret_val = gets(a_sep_string)
        raise EOFError unless ret_val

        ret_val
      end

      def each_line(a_sep_string = $INPUT_RECORD_SEPARATOR)
        loop { yield readline(a_sep_string) }
      rescue EOFError
        # We just need to catch this; we don't need to handle it.
      end

      alias each each_line

      def eof
        @output_buffer.empty? && input_finished?
      end

      alias eof? eof
    end
  end
end
