module Zip
  class PassThruDecompressor < Decompressor #:nodoc:all
    def initialize(*args)
      super
      @read_so_far = 0
    end

    def read(length = nil, outbuf = '')
      return (length.nil? || length.zero? ? '' : nil) if eof

      if length.nil? || (@read_so_far + length) > decompressed_size
        length = decompressed_size - @read_so_far
      end

      @read_so_far += length
      input_stream.read(length, outbuf)
    end

    def eof
      @read_so_far >= decompressed_size
    end

    alias eof? eof
  end

  ::Zip::Decompressor.register(::Zip::COMPRESSION_METHOD_STORE, ::Zip::PassThruDecompressor)
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
