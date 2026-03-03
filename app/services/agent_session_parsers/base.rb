module AgentSessionParsers
  class ParseError < StandardError; end

  class Base
    MAX_JSON_NESTING = 50
    MAX_RECORDS = 50_000
    MAX_OUTPUT_LENGTH = 2000

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
        "metadata" => metadata
      }
    end

    def build_message(role:, content_blocks:, timestamp: nil, model: nil)
      msg = { "role" => role, "content" => content_blocks }
      msg["timestamp"] = timestamp if timestamp
      msg["model"] = model if model
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
      records = []
      raw_content.each_line do |line|
        line = line.strip
        next if line.empty?

        record = JSON.parse(line, max_nesting: MAX_JSON_NESTING)
        records << record
        break if records.size >= MAX_RECORDS
      rescue JSON::ParserError
        next
      end
      records
    end

    # Attach output to the first tool_call block that matches the predicate (or has no output).
    # Without a block, matches the first unmatched tool_call.
    def attach_output_to_tool_call(messages, output)
      catch(:attached) do
        messages.each do |m|
          next unless m["role"] == "assistant"

          m["content"]&.each do |b|
            next unless b["type"] == "tool_call" && b["output"].nil?
            next if block_given? && !yield(b)

            b["output"] = output
            throw :attached
          end
        end
      end
    end

    def truncate_output(text, max_length: MAX_OUTPUT_LENGTH)
      return text if text.nil? || text.length <= max_length

      "#{text[0...max_length]}\n... (truncated)"
    end
  end
end
