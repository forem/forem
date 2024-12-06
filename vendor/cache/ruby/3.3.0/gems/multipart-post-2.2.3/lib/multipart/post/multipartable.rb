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

require_relative 'parts'
require_relative 'composite_read_io'

require 'securerandom'

module Multipart
  module Post
    module Multipartable
      def self.secure_boundary
        # https://tools.ietf.org/html/rfc7230
        #      tchar          = "!" / "#" / "$" / "%" / "&" / "'" / "*"
        #                     / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
        #                     / DIGIT / ALPHA

        # https://tools.ietf.org/html/rfc2046
        #      bcharsnospace := DIGIT / ALPHA / "'" / "(" / ")" /
        #                       "+" / "_" / "," / "-" / "." /
        #                       "/" / ":" / "=" / "?"

        "--#{SecureRandom.uuid}"
      end

      def initialize(path, params, headers={}, boundary = Multipartable.secure_boundary)
        headers = headers.clone # don't want to modify the original variable
        parts_headers = symbolize_keys(headers.delete(:parts) || {})

        super(path, headers)
        parts = symbolize_keys(params).map do |k,v|
          case v
          when Array
            v.map {|item| Parts::Part.new(boundary, k, item, parts_headers[k]) }
          else
            Parts::Part.new(boundary, k, v, parts_headers[k])
          end
        end.flatten
        parts << Parts::EpiloguePart.new(boundary)
        ios = parts.map {|p| p.to_io }
        self.set_content_type(headers["Content-Type"] || "multipart/form-data",
                              { "boundary" => boundary })
        self.content_length = parts.inject(0) {|sum,i| sum + i.length }
        self.body_stream = CompositeReadIO.new(*ios)

        @boundary = boundary
      end

      attr :boundary

      private

      if RUBY_VERSION >= "2.5.0"
        def symbolize_keys(hash)
          hash.transform_keys(&:to_sym)
        end
      else
        def symbolize_keys(hash)
          hash.map{|key,value| [key.to_sym, value]}.to_h
        end
      end
    end
  end
end

Multipartable = Multipart::Post::Multipartable
Object.deprecate_constant :Multipartable
