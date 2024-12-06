module Zip
  module NullDecompressor #:nodoc:all
    module_function

    def read(_length = nil, _outbuf = nil)
      nil
    end

    def eof
      true
    end

    alias eof? eof
  end
end

# Copyright (C) 2002, 2003 Thomas Sondergaard
# rubyzip is free software; you can redistribute it and/or
# modify it under the terms of the ruby license.
