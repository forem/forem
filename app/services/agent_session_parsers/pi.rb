module AgentSessionParsers
  class Pi < Base
    def parse
      records = parse_jsonl_lines
      messages = []

      # Separate message records from metadata records
      msg_records = records.select { |r| r["type"] == "message" }

      msg_records.each do |record|
        msg = record["message"] || {}
        role = msg["role"]
        timestamp = record["timestamp"]

        case role
        when "user"
          text = extract_text_content(msg["content"])
          messages << build_message(role: "user", content_blocks: [text_block(text)], timestamp: timestamp) if text.present?
        when "assistant"
          emit_assistant_messages(msg["content"], messages, timestamp)
        when "toolResult"
          output = extract_text_content(msg["content"])
          attach_output_to_first_unmatched(messages, truncate_output(output)) if output.present?
        end
      end

      metadata = extract_metadata(records, messages)
      build_result(messages: messages, metadata: metadata)
    end

    private

    def emit_assistant_messages(content_blocks, messages, timestamp)
      return unless content_blocks.is_a?(Array)

      text_parts = []

      content_blocks.each do |block|
        case block["type"]
        when "thinking"
          text = block["thinking"]
          text_parts << "**Thinking:** #{text.truncate(300)}" if text.present?
        when "text"
          text_parts << block["text"] if block["text"].present?
        when "toolCall"
          # Flush any pending text as its own message
          if text_parts.any?
            messages << build_message(role: "assistant", content_blocks: [text_block(text_parts.join("\n\n"))], timestamp: timestamp)
            text_parts.clear
          end

          name = block["name"] || "tool_call"
          input = block["arguments"]
          input_str = input.is_a?(String) ? input.truncate(200) : input&.to_json&.truncate(200)
          messages << build_message(
            role: "assistant",
            content_blocks: [tool_call_block(name: name, input: input_str, output: nil)],
            timestamp: timestamp,
          )
        end
      end

      # Flush remaining text
      if text_parts.any?
        messages << build_message(role: "assistant", content_blocks: [text_block(text_parts.join("\n\n"))], timestamp: timestamp)
      end
    end

    def extract_text_content(content)
      case content
      when String then content
      when Array
        content.filter_map { |c| c["text"] if c["type"] == "text" }.join("\n")
      else
        ""
      end
    end

    def attach_output_to_first_unmatched(messages, output)
      messages.each do |m|
        next unless m["role"] == "assistant"

        m["content"]&.each do |b|
          if b["type"] == "tool_call" && b["output"].nil?
            b["output"] = output
            return
          end
        end
      end
    end

    def extract_metadata(records, messages)
      session = records.find { |r| r["type"] == "session" } || records.first
      model_change = records.find { |r| r["type"] == "model_change" }

      {
        "tool_name" => "pi",
        "session_id" => session&.dig("id"),
        "start_time" => session&.dig("timestamp"),
        "model" => model_change&.dig("modelId"),
        "total_messages" => messages.size,
        "working_directory" => session&.dig("cwd"),
      }.compact
    end
  end
end
