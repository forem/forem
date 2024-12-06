# frozen_string_literal: true
module Excon
  module Utils
    extend self

    CONTROL   = (0x0..0x1f).map {|c| c.chr }.join + "\x7f"
    DELIMS    = '<>#%"'
    UNWISE    = '{}|\\^[]`'
    NONASCII  = (0x80..0xff).map {|c| c.chr }.join
    UNESCAPED = /([#{ Regexp.escape(CONTROL + ' ' + DELIMS + UNWISE + NONASCII) }])/
    ESCAPED   = /%([0-9a-fA-F]{2})/

    def binary_encode(string)
      if FORCE_ENC && string.encoding != Encoding::ASCII_8BIT
        if string.frozen?
          string.dup.force_encoding('BINARY')
        else
          string.force_encoding('BINARY')
        end
      else
        string
      end
    end

    def connection_uri(datum = @data)
      unless datum
        raise ArgumentError, '`datum` must be given unless called on a Connection'
      end
      if datum[:scheme] == UNIX
        "#{datum[:scheme]}://#{datum[:socket]}"
      else
        "#{datum[:scheme]}://#{datum[:host]}#{port_string(datum)}"
      end
    end

    # Redact sensitive info from provided data
    def redact(datum)
      datum = datum.dup
      if datum.has_key?(:headers)
        if datum[:headers].has_key?('Authorization') || datum[:headers].has_key?('Proxy-Authorization')
          datum[:headers] = datum[:headers].dup
        end
        if datum[:headers].has_key?('Authorization')
          datum[:headers]['Authorization'] = REDACTED
        end
        if datum[:headers].has_key?('Proxy-Authorization')
          datum[:headers]['Proxy-Authorization'] = REDACTED
        end
      end
      if datum.has_key?(:password)
        datum[:password] = REDACTED
      end
      if datum.has_key?(:proxy) && datum[:proxy] && datum[:proxy].has_key?(:password)
        datum[:proxy] = datum[:proxy].dup
        datum[:proxy][:password] = REDACTED
      end
      datum
    end

    def request_uri(datum)
      connection_uri(datum) + datum[:path] + query_string(datum)
    end

    def port_string(datum)
      if datum[:port].nil? || (datum[:omit_default_port] && ((datum[:scheme].casecmp('http') == 0 && datum[:port] == 80) || (datum[:scheme].casecmp('https') == 0 && datum[:port] == 443)))
        ''
      else
        ':' + datum[:port].to_s
      end
    end

    def query_string(datum)
      str = String.new
      case datum[:query]
      when String
        str << '?' << datum[:query]
      when Hash
        str << '?'
        datum[:query].sort_by {|k,_| k.to_s }.each do |key, values|
          key = CGI.escape(key.to_s)
          if values.nil?
            str << key << '&'
          else
            [values].flatten.each do |value|
              str << key << '=' << CGI.escape(value.to_s) << '&'
            end
          end
        end
        str.chop! # remove trailing '&'
      end
      str
    end

    # Splits a header value +str+ according to HTTP specification.
    def split_header_value(str)
      return [] if str.nil?
      str = str.dup.strip
      str = binary_encode(str)
      str.scan(%r'\G((?:"(?:\\.|[^"])+?"|[^",])+)
                    (?:,\s*|\Z)'xn).flatten
    end

    # Escapes HTTP reserved and unwise characters in +str+
    def escape_uri(str)
      str = str.dup
      str = binary_encode(str)
      str.gsub(UNESCAPED) { "%%%02X" % $1[0].ord }
    end

    # Unescapes HTTP reserved and unwise characters in +str+
    def unescape_uri(str)
      str = str.dup
      str = binary_encode(str)
      str.gsub(ESCAPED) { $1.hex.chr }
    end

    # Unescape form encoded values in +str+
    def unescape_form(str)
      str = str.dup
      str = binary_encode(str)
      str.gsub!(/\+/, ' ')
      str.gsub(ESCAPED) { $1.hex.chr }
    end

    # Performs validation on the passed header hash and returns a string representation of the headers
    def headers_hash_to_s(headers)
      headers_str = String.new
      headers.each do |key, values|
        if key.to_s.match(/[\r\n]/)
          raise Excon::Errors::InvalidHeaderKey.new(key.to_s.inspect + ' contains forbidden "\r" or "\n"')
        end
        [values].flatten.each do |value|
          if value.to_s.match(/[\r\n]/)
            # Don't include the potentially sensitive header value (i.e. authorization token) in the message
            raise Excon::Errors::InvalidHeaderValue.new(key.to_s + ' header value contains forbidden "\r" or "\n"')
          end
          headers_str << key.to_s << ': ' << value.to_s << CR_NL
        end
      end
      headers_str
    end
  end
end
