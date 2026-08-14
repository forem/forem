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

          unless block.is_a?(Hash) && VALID_BLOCK_TYPES.include?(block["type"])
            errors << ValidationError.new(
              message: "Message #{i}, block #{bi} has invalid type: #{block.is_a?(Hash) ? block['type'] : 'non-object'}",
            )
          end
        end
      end

      errors
    end

    def validate_size
      errors = []

      json_size = @data.to_json.bytesize
      if json_size > MAX_JSON_SIZE
        errors << ValidationError.new(message: "Normalized data is too large (#{json_size} bytes, max #{MAX_JSON_SIZE})")
      end

      errors
    end
  end
end
