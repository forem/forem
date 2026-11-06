module AgentSessionParsers
  class NormalizedDataValidator
    MAX_MESSAGES = 50_000
    MAX_JSON_SIZE = 10.megabytes
    VALID_ROLES = %w[user assistant].freeze
    VALID_BLOCK_TYPES = %w[text tool_call].freeze

    ValidationError = Struct.new(:message, keyword_init: true)

    def self.validate(data)
      new(data).validate
    end

    def initialize(data)
      @data = data
    end

    def validate
      errors = []

      unless @data.is_a?(Hash)
        return [ValidationError.new(message: "Normalized data must be a JSON object")]
      end

      errors.concat(validate_structure)
      errors.concat(validate_messages) if errors.empty?
      errors.concat(validate_size) if errors.empty?

      errors
    end

    private

    def validate_structure
      errors = []

      unless @data.key?("messages")
        errors << ValidationError.new(message: "Missing required key: messages")
        return errors
      end

      unless @data["messages"].is_a?(Array)
        errors << ValidationError.new(message: "messages must be an array")
        return errors
      end

      unless @data["metadata"].nil? || @data["metadata"].is_a?(Hash)
        errors << ValidationError.new(message: "metadata must be a JSON object")
      end

      errors
    end

    # Validates message count, roles, and content blocks, returning up to five errors.
    def validate_messages
      errors = []
      msgs = @data["messages"]

      if msgs.size > MAX_MESSAGES
        errors << ValidationError.new(message: "Too many messages (max #{MAX_MESSAGES})")
        return errors
      end

      msgs.each_with_index do |msg, i|
        break if errors.size >= 5

        unless msg.is_a?(Hash)
          errors << ValidationError.new(message: "Message at index #{i} must be a JSON object")
          next
        end

        unless VALID_ROLES.include?(msg["role"])
          errors << ValidationError.new(message: "Message at index #{i} has invalid role: #{msg['role']}")
        end

        content = msg["content"]
        unless content.is_a?(Array)
          errors << ValidationError.new(message: "Message at index #{i} must have a content array")
          next
        end

        content.each_with_index do |block, bi|
          break if errors.size >= 5

          next if block.is_a?(Hash) && VALID_BLOCK_TYPES.include?(block["type"])

          type = block.is_a?(Hash) ? block["type"] : "non-object"
          errors << ValidationError.new(message: "Message #{i}, block #{bi} has invalid type: #{type}")
        end
      end

      errors
    end

    # Counts encoded JSON bytes via ForemNative when using the default ActiveSupport encoder.
    def native_json_size
      encoding = ActiveSupport::JSON::Encoding
      return unless encoding.json_encoder == encoding::JSONGemEncoder

      ForemNative.json_encoded_size(@data, escape_html_entities: encoding.escape_html_entities_in_json)
    end

    # Measures encoded JSON byte size by serializing @data through ActiveSupport#to_json.
    def legacy_json_size
      @data.to_json.bytesize
    end

    # Validates that the encoded JSON representation of @data does not exceed MAX_JSON_SIZE.
    def validate_size
      errors = []

      json_size = native_json_size || legacy_json_size
      if json_size > MAX_JSON_SIZE
        errors << ValidationError.new(
          message: "Normalized data is too large (#{json_size} bytes, max #{MAX_JSON_SIZE})",
        )
      end

      errors
    end
  end
end
