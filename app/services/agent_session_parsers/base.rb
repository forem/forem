module AgentSessionParsers
  class Base
    def self.parse(raw_content)
      new(raw_content).parse
    end

    def initialize(raw_content)
      @raw_content = raw_content
    end

    def parse
      raise NotImplementedError, "#{self.class}#parse must be implemented"
    end

    private

    attr_reader :raw_content

    def build_result(messages:, metadata: {})
      indexed = messages.each_with_index.map do |msg, i|
        msg.merge("index" => i)
      end

      {
        "messages" => indexed,
        "metadata" => metadata,
      }
    end

    def build_message(role:, content_blocks:, timestamp: nil)
      msg = { "role" => role, "content" => content_blocks }
      msg["timestamp"] = timestamp if timestamp
      msg
    end

    def text_block(text)
      { "type" => "text", "text" => text }
    end

    def tool_call_block(name:, input: nil, output: nil)
      block = { "type" => "tool_call", "name" => name }
      block["input"] = input if input
      block["output"] = output if output
      block
    end

    def parse_jsonl_lines
      raw_content.each_line.filter_map do |line|
        line = line.strip
        next if line.empty?

        JSON.parse(line, max_nesting: 50)
      rescue JSON::ParserError
        nil
      end
    end

    def truncate_output(text, max_length: 2000)
      return text if text.nil? || text.length <= max_length

      "#{text[0...max_length]}\n... (truncated)"
    end
  end
end
