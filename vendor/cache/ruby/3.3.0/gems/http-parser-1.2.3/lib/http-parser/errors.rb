# frozen_string_literal: true

module HttpParser
    class Error < StandardError
        class OK < Error; end

        # Any callback-related errors
        class CALLBACK < Error; end

        # Parsing-related errors
        class INVALID_EOF_STATE < Error; end
        class HEADER_OVERFLOW < Error; end
        class CLOSED_CONNECTION < Error; end

        class INVALID_VERSION < Error; end
        class INVALID_STATUS < Error; end
        class INVALID_METHOD < Error; end
        class INVALID_URL < Error; end
        class INVALID_HOST < Error; end
        class INVALID_PORT < Error; end
        class INVALID_PATH < Error; end
        class INVALID_QUERY_STRING < Error; end
        class INVALID_FRAGMENT < Error; end
        class LF_EXPECTED < Error; end
        class INVALID_HEADER_TOKEN < Error; end
        class INVALID_CONTENT_LENGTH < Error; end
        class INVALID_CHUNK_SIZE < Error; end
        class INVALID_CONSTANT < Error; end
        class INVALID_INTERNAL_STATE < Error; end
        class STRICT < Error; end
        class PAUSED < Error; end

        class UNKNOWN < Error; end
    end

    ERRORS = {
        :OK => Error::OK,

        :CB_message_begin => Error::CALLBACK,
        :CB_url => Error::CALLBACK,
        :CB_header_field => Error::CALLBACK,
        :CB_header_value => Error::CALLBACK,
        :CB_headers_complete => Error::CALLBACK,
        :CB_body => Error::CALLBACK,
        :CB_message_complete => Error::CALLBACK,
        :CB_status => Error::CALLBACK,
        :CB_chunk_header => Error::CALLBACK,
        :CB_chunk_complete => Error::CALLBACK,

        :INVALID_EOF_STATE => Error::INVALID_EOF_STATE,
        :HEADER_OVERFLOW => Error::HEADER_OVERFLOW,
        :CLOSED_CONNECTION => Error::CLOSED_CONNECTION,
        :INVALID_VERSION => Error::INVALID_VERSION,
        :INVALID_STATUS => Error::INVALID_STATUS,
        :INVALID_METHOD => Error::INVALID_METHOD,
        :INVALID_URL => Error::INVALID_URL,
        :INVALID_HOST => Error::INVALID_HOST,
        :INVALID_PORT => Error::INVALID_PORT,
        :INVALID_PATH => Error::INVALID_PATH,
        :INVALID_QUERY_STRING => Error::INVALID_QUERY_STRING,
        :INVALID_FRAGMENT => Error::INVALID_FRAGMENT,
        :LF_EXPECTED => Error::LF_EXPECTED,
        :INVALID_HEADER_TOKEN => Error::INVALID_HEADER_TOKEN,
        :INVALID_CONTENT_LENGTH => Error::INVALID_CONTENT_LENGTH,
        :INVALID_CHUNK_SIZE => Error::INVALID_CHUNK_SIZE,
        :INVALID_CONSTANT => Error::INVALID_CONSTANT,
        :INVALID_INTERNAL_STATE => Error::INVALID_INTERNAL_STATE,
        :STRICT => Error::STRICT,
        :PAUSED => Error::PAUSED,

        :UNKNOWN => Error::UNKNOWN
    }

    attach_function :err_desc, :http_errno_description, [:int], :string
    attach_function :err_name, :http_errno_name, [:int], :string
end

