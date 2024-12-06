# frozen_string_literal: true

module HttpParser
    HTTP_MAX_HEADER_SIZE = (80 * 1024)

    #
    # These share a byte of data as a bitmap
    #
    TYPES = enum :http_parser_type, [
        :request, 0, 
        :response,
        :both
    ]
    FLAG = {
        :CHUNKED => 1 << 2,
        :CONNECTION_KEEP_ALIVE => 1 << 3,
        :CONNECTION_CLOSE => 1 << 4,
        :CONNECTION_UPGRADE => 1 << 5,
        :TRAILING => 1 << 6,
        :UPGRADE => 1 << 7,
        :SKIPBODY => 1 << 8
    }

    #
    # Request Methods
    #
    METHODS = enum :http_method, [
        :DELETE, 0,
        :GET,
        :HEAD,
        :POST,
        :PUT,
        # pathological
        :CONNECT,
        :OPTIONS,
        :TRACE,
        # webdav
        :COPY,
        :LOCK,
        :MKCOL,
        :MOVE,
        :PROPFIND,
        :PROPPATCH,
        :SEARCH,
        :UNLOCK,
        :BIND,
        :REBIND,
        :UNBIND,
        :ACL,
        # subversion
        :REPORT,
        :MKACTIVITY,
        :CHECKOUT,
        :MERGE,
        # upnp
        :MSEARCH,
        :NOTIFY,
        :SUBSCRIBE,
        :UNSUBSCRIBE,
        # RFC-5789
        :PATCH,
        :PURGE,
        # CalDAV
        :MKCALENDAR,
        # RFC-2068, section 19.6.1.2
        :LINK,
        :UNLINK
    ]


    UrlFields = enum :http_parser_url_fields, [
        :SCHEMA, 0,
        :HOST,
        :PORT,
        :PATH,
        :QUERY,
        :FRAGMENT,
        :USERINFO,
        :MAX
    ]


    #
    # Effectively this represents a request instance
    #
    class Instance < FFI::Struct
        layout  :type_flags,     :uchar,
                :state,          :uchar,
                :header_state,   :uchar,
                :index,          :uchar,

                :nread,          :uint32,
                :content_length, :uint64,

                # READ-ONLY
                :http_major,     :ushort,
                :http_minor,     :ushort,
                :status_code,    :ushort, # responses only
                :method,         :uchar,  # requests only
                :error_upgrade,  :uchar,  # errno = first 7bits, upgrade = last bit

                # PUBLIC
                :data,           :pointer


        def initialize(ptr = nil)
            if ptr then super(ptr)
            else
                super()
                self.type = :both
            end

            yield self if block_given?

            ::HttpParser.http_parser_init(self, self.type) unless ptr
        end

        #
        # Resets the parser.
        #
        # @param [:request, :response, :both] new_type
        #   The new type for the parser.
        #
        def reset!(new_type = type)
            ::HttpParser.http_parser_init(self, new_type)
        end

        #
        # The type of the parser.
        #
        # @return [:request, :response, :both]
        #   The parser type.
        #
        def type
            TYPES[self[:type_flags] & 0x3]
        end

        #
        # Sets the type of the parser.
        #
        # @param [:request, :response, :both] new_type
        #   The new parser type.
        #
        def type=(new_type)
            self[:type_flags] = (flags | TYPES[new_type])
        end

        #
        # Flags for the parser.
        #
        # @return [Integer]
        #   Parser flags.
        #
        def flags
            (self[:type_flags] & 0xfc)
        end

        #
        # The parsed HTTP major version number.
        #
        # @return [Integer]
        #   The HTTP major version number.
        #
        def http_major
            self[:http_major]
        end

        #
        # The parsed HTTP minor version number.
        #
        # @return [Integer]
        #   The HTTP minor version number.
        #
        def http_minor
            self[:http_minor]
        end

        #
        # The parsed HTTP version.
        #
        # @return [String]
        #   The HTTP version.
        #
        def http_version
            "%d.%d" % [self[:http_major], self[:http_minor]]
        end

        #
        # The parsed HTTP response Status Code.
        #
        # @return [Integer]
        #   The HTTP Status Code.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec6.html#sec6.1.1
        #
        def http_status
            self[:status_code]
        end

        #
        # The parsed HTTP Method.
        #
        # @return [Symbol]
        #   The HTTP Method name.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.1.1
        #
        def http_method
            METHODS[self[:method]]
        end

        #
        # Determines whether the `Upgrade` header has been parsed.
        #
        # @return [Boolean]
        #   Specifies whether the `Upgrade` header has been seen.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.42
        #
        def upgrade?
            (self[:error_upgrade] & 0b10000000) > 0
        end

        #
        # Determines whether an error occurred during processing.
        #
        # @return [Boolean]
        #   Did a parsing error occur with the request?
        #
        def error?
            error = (self[:error_upgrade] & 0b1111111)
            return error != 0
        end

        #
        # Returns the error that occurred during processing.
        #
        # @return [StandarError]
        #   Returns the error that occurred.
        #
        def error
            error = (self[:error_upgrade] & 0b1111111)
            return nil if error == 0

            err = ::HttpParser.err_name(error)[4..-1] # HPE_ is at the start of all these errors
            klass = ERRORS[err.to_sym]
            err = "#{::HttpParser.err_desc(error)} (#{err})"
            return klass.nil? ? Error::UNKNOWN.new(err) : klass.new(err)
        end

        #
        # Additional data attached to the parser.
        #
        # @return [FFI::Pointer]
        #   Pointer to the additional data.
        #
        def data
            self[:data]
        end

        #
        # Determines whether the `Connection: keep-alive` header has been
        # parsed.
        #
        # @return [Boolean]
        #   Specifies whether the Connection should be kept alive.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.10
        #
        def keep_alive?
            ::HttpParser.http_should_keep_alive(self) > 0
        end

        #
        # Determines if a chunked response has completed
        #
        # @return [Boolean]
        #   Specifies whether the chunked response has completed
        #
        def final_chunk?
            ::HttpParser.http_body_is_final(self) > 0
        end

        #
        # Halts the parser if called in a callback
        #
        def stop!
            throw :return, 1
        end

        #
        # Indicates an error has occurred when called in a callback
        #
        def error!
            throw :return, -1
        end
    end

    class FieldData < FFI::Struct
        layout  :off,   :uint16,
                :len,   :uint16
    end

    class HttpParserUrl < FFI::Struct
        layout  :field_set,     :uint16,
                :port,          :uint16,
                :field_data,    [FieldData, UrlFields[:MAX]]
    end


    callback :http_data_cb, [Instance.ptr, :pointer, :size_t], :int
    callback :http_cb,      [Instance.ptr], :int


    class Settings < FFI::Struct
        layout  :on_message_begin,    :http_cb,
                :on_url,              :http_data_cb,
                :on_status,           :http_data_cb,
                :on_header_field,     :http_data_cb,
                :on_header_value,     :http_data_cb,
                :on_headers_complete, :http_cb,
                :on_body,             :http_data_cb,
                :on_message_complete, :http_cb,
                :on_chunk_header,     :http_cb,
                :on_chunk_complete,   :http_cb
    end


    attach_function :http_parser_init, [Instance.by_ref, :http_parser_type], :void
    attach_function :http_parser_execute, [Instance.by_ref, Settings.by_ref, :pointer, :size_t], :size_t
    attach_function :http_should_keep_alive, [Instance.by_ref], :int

    # Checks if this is the final chunk of the body
    attach_function :http_body_is_final, [Instance.by_ref], :int
end
