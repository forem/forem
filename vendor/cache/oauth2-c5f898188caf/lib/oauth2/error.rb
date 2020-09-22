module OAuth2
  class Error < StandardError
    attr_reader :response, :code, :description

    # standard error codes include:
    # 'invalid_request', 'invalid_client', 'invalid_token', 'invalid_grant', 'unsupported_grant_type', 'invalid_scope'
    def initialize(response)
      @response = response
      message_opts = {}

      if response.parsed.is_a?(Hash)
        @code = response.parsed['error']
        @description = response.parsed['error_description']
        message_opts = parse_error_description(@code, @description)
      end

      super(error_message(response.body, message_opts))
    end

  private

    def error_message(response_body, opts = {})
      lines = []

      lines << opts[:error_description] if opts[:error_description]

      error_string = if response_body.respond_to?(:encode) && opts[:error_description].respond_to?(:encoding)
                       script_encoding = opts[:error_description].encoding
                       response_body.encode(script_encoding, :invalid => :replace, :undef => :replace)
                     else
                       response_body
                     end

      lines << error_string

      lines.join("\n")
    end

    def parse_error_description(code, description)
      return {} unless code || description

      error_description = ''
      error_description << "#{code}: " if code
      error_description << description if description

      {:error_description => error_description}
    end
  end
end
