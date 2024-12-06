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
    # Convenience methods for dealing with files and IO that are to be uploaded.
    class UploadIO
      attr_reader :content_type, :original_filename, :local_path, :io, :opts

      # Create an upload IO suitable for including in the params hash of a
      # Net::HTTP::Post::Multipart.
      #
      # Can take two forms. The first accepts a filename and content type, and
      # opens the file for reading (to be closed by finalizer).
      #
      # The second accepts an already-open IO, but also requires a third argument,
      # the filename from which it was opened (particularly useful/recommended if
      # uploading directly from a form in a framework, which often save the file to
      # an arbitrarily named RackMultipart file in /tmp).
      #
      # @example
      #     UploadIO.new("file.txt", "text/plain")
      #     UploadIO.new(file_io, "text/plain", "file.txt")
      def initialize(filename_or_io, content_type, filename = nil, opts = {})
        io = filename_or_io
        local_path = ""
        if io.respond_to? :read
          # in Ruby 1.9.2, StringIOs no longer respond to path
          # (since they respond to :length, so we don't need their local path, see parts.rb:41)
          local_path = filename_or_io.respond_to?(:path) ? filename_or_io.path : "local.path"
        else
          io = File.open(filename_or_io)
          local_path = filename_or_io
        end
        filename ||= local_path

        @content_type = content_type
        @original_filename = File.basename(filename)
        @local_path = local_path
        @io = io
        @opts = opts
      end

      def self.convert!(io, content_type, original_filename, local_path)
        raise ArgumentError, "convert! has been removed. You must now wrap IOs " \
          "using:\nUploadIO.new(filename_or_io, content_type, " \
          "filename=nil)\nPlease update your code."
      end

      def method_missing(*args)
        @io.send(*args)
      end

      def respond_to?(meth, include_all = false)
        @io.respond_to?(meth, include_all) || super(meth, include_all)
      end
    end
  end
end

UploadIO = Multipart::Post::UploadIO
Object.deprecate_constant :UploadIO
