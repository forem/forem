require 'cgi'

module NetHttp2

  class Request

    include Callbacks

    DEFAULT_TIMEOUT = 60

    attr_reader :method, :uri, :path, :params, :body, :timeout

    def initialize(method, uri, path, options={})
      @method  = method
      @uri     = uri
      @path    = path
      @params  = options[:params] || {}
      @body    = options[:body]
      @headers = options[:headers] || {}
      @timeout = options[:timeout] || DEFAULT_TIMEOUT

      @events = {}
    end

    def headers
      @headers.merge!({
        ':scheme' => @uri.scheme,
        ':method' => @method.to_s.upcase,
        ':path'   => full_path,
      })

      @headers.merge!(':authority' => "#{@uri.host}:#{@uri.port}") unless @headers[':authority']

      if @body
        @headers.merge!('content-length' => @body.bytesize)
      else
        @headers.delete('content-length')
      end

      @headers.update(@headers) { |_k, v| v.to_s }

      # see <https://github.com/ostinelli/apnotic/issues/68>
      @headers.sort.to_h
    end

    def full_path
      path = @path
      path += "?#{to_query(@params)}" unless @params.empty?
      path
    end

    private

    # The to_param and to_query code here below is a free adaptation from the original code in:
    # <https://github.com/rails/rails/blob/v5.0.0.1/activesupport/lib/active_support/core_ext/object/to_query.rb>
    # released under the following MIT license:
    #
    # Copyright (c) 2005-2016 David Heinemeier Hansson
    #
    # Permission is hereby granted, free of charge, to any person obtaining
    # a copy of this software and associated documentation files (the
    # "Software"), to deal in the Software without restriction, including
    # without limitation the rights to use, copy, modify, merge, publish,
    # distribute, sublicense, and/or sell copies of the Software, and to
    # permit persons to whom the Software is furnished to do so, subject to
    # the following conditions:
    #
    # The above copyright notice and this permission notice shall be
    # included in all copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    # NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    # LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    # OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    # WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    def to_param(element)
      if element.is_a?(TrueClass) || element.is_a?(FalseClass) || element.is_a?(NilClass)
        element
      elsif element.is_a?(Array)
        element.collect(&:to_param).join '/'
      else
        element.to_s.strip
      end
    end

    def to_query(element, namespace_or_key = nil)
      if element.is_a?(Hash)
        element.collect do |key, value|
          unless (value.is_a?(Hash) || value.is_a?(Array)) && value.empty?
            to_query(value, namespace_or_key ? "#{namespace_or_key}[#{key}]" : key)
          end
        end.compact.sort! * '&'
      elsif element.is_a?(Array)
        prefix = "#{namespace_or_key}[]"

        if element.empty?
          to_query(nil, prefix)
        else
          element.collect { |value| to_query(value, prefix) }.join '&'
        end
      else
        "#{CGI.escape(to_param(namespace_or_key))}=#{CGI.escape(to_param(element).to_s)}"
      end
    end
  end
end
