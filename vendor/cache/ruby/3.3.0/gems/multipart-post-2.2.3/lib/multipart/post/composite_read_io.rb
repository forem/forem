# frozen_string_literal: true

# Copyright, 2007-2013, by Nick Sieger.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Multipart
  module Post
    # Concatenate together multiple IO objects into a single, composite IO object
    # for purposes of reading as a single stream.
    #
    # @example
    #     crio = CompositeReadIO.new(StringIO.new('one'),
    #                                StringIO.new('two'),
    #                                StringIO.new('three'))
    #     puts crio.read # => "onetwothree"
    class CompositeReadIO
      # Create a new composite-read IO from the arguments, all of which should
      # respond to #read in a manner consistent with IO.
      def initialize(*ios)
        @ios = ios.flatten
        @index = 0
      end

      # Read from IOs in order until `length` bytes have been received.
      def read(length = nil, outbuf = nil)
        got_result = false
        outbuf = outbuf ? outbuf.replace("") : String.new

        while io = current_io
          if result = io.read(length)
            got_result ||= !result.nil?
            result.force_encoding("BINARY") if result.respond_to?(:force_encoding)
            outbuf << result
            length -= result.length if length
            break if length == 0
          end
          advance_io
        end
        (!got_result && length) ? nil : outbuf
      end

      def rewind
        @ios.each { |io| io.rewind }
        @index = 0
      end

      private

      def current_io
        @ios[@index]
      end

      def advance_io
        @index += 1
      end
    end
  end
end

CompositeIO = Multipart::Post::CompositeReadIO
Object.deprecate_constant :CompositeIO
