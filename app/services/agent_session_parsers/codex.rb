module AgentSessionParsers
  class Codex < Base
    def parse
      records = parse_jsonl_lines
      messages = []
      current_assistant_blocks = []

      records.each do |record|
        case record["type"]
        when "event_msg"
          handle_event_msg(record, messages, current_assistant_blocks)
        when "response_item"
          handle_response_item(record, messages, current_assistant_blocks)
        when "item.completed"
          handle_item_completed(record, messages, current_assistant_blocks)
        when "turn.completed", "turn_context"
          flush_assistant_blocks(messages, current_assistant_blocks)
        end
      end

      flush_assistant_blocks(messages, current_assistant_blocks)

      metadata = extract_metadata(records, messages)
      build_result(messages: messages, metadata: metadata)
    end

    private

    def handle_event_msg(record, messages, current_assistant_blocks)
      payload = record["payload"] || {}
      return unless payload["type"] == "user_message"

      flush_assistant_blocks(messages, current_assistant_blocks)
      text = payload["message"] || payload["text"] || payload.dig("content", 0, "text") || ""
      return if text.blank?

      messages << build_message(role: "user", content_blocks: [text_block(text)])
    end

    # New Codex format (0.105+): response_item records
    def handle_response_item(record, messages, current_assistant_blocks)
      payload = record["payload"] || {}
      role = payload["role"]
      item_type = payload["type"]

      case item_type
      when "message"
        if role == "user"
          # In new Codex format, user messages come from event_msg (user_message payload).
          # response_item role=user contains duplicates plus system instructions — skip them.
          return
        elsif role == "assistant"
          text = extract_response_item_text(payload)
          if text.present?
            # Flush any pending tool calls before starting text
            flush_assistant_blocks(messages, current_assistant_blocks) if current_assistant_blocks.any? { |b| b["type"] == "tool_call" }
            current_assistant_blocks << text_block(text)
          end
        end
        # Skip developer role (system instructions)
      when "function_call", "custom_tool_call"
        # Flush any pending text blocks as their own message
        flush_assistant_blocks(messages, current_assistant_blocks)

        name = payload["name"] || payload["call_id"] || "tool_call"
        input = payload["arguments"] || payload["input"]
        # Each tool call becomes its own message (output paired later)
        current_assistant_blocks << tool_call_block(
          name: name,
          input: input.is_a?(String) ? input.truncate(200) : input&.to_json&.truncate(200),
          output: nil,
        )
        flush_assistant_blocks(messages, current_assistant_blocks)
      when "function_call_output", "custom_tool_call_output"
        output = extract_output_content(payload)
        formatted = truncate_output(output)
        # Find the first tool_call in already-flushed messages that has no output yet
        attach_output_to_first_unmatched(messages, formatted)
      when "reasoning"
        summary = payload.dig("summary", 0, "text")
        if summary.present?
          flush_assistant_blocks(messages, current_assistant_blocks) if current_assistant_blocks.any? { |b| b["type"] == "tool_call" }
          current_assistant_blocks << text_block(summary)
        end
      end
    end

    # Old Codex format: item.completed records
    def handle_item_completed(record, messages, current_assistant_blocks)
      item = record["item"] || {}
      item_type = item["type"]

      case item_type
      when "message"
        text = extract_message_text(item)
        if text.present?
          flush_assistant_blocks(messages, current_assistant_blocks) if current_assistant_blocks.any? { |b| b["type"] == "tool_call" }
          current_assistant_blocks << text_block(text)
        end
      when "function_call", "command"
        flush_assistant_blocks(messages, current_assistant_blocks) if current_assistant_blocks.any? { |b| b["type"] == "text" }
        name = item["name"] || item["command"] || "command"
        input = item.dig("arguments") || item.dig("input") || item.dig("command")
        raw_output = item.dig("output") || item.dig("result")
        output_text = unwrap_json_output(raw_output)
        current_assistant_blocks << tool_call_block(
          name: name,
          input: input.is_a?(String) ? input : input&.to_json&.truncate(200),
          output: truncate_output(output_text.is_a?(String) ? output_text : output_text&.to_json),
        )
        flush_assistant_blocks(messages, current_assistant_blocks)
      when "file_change"
        flush_assistant_blocks(messages, current_assistant_blocks) if current_assistant_blocks.any? { |b| b["type"] == "text" }
        path = item["file_path"] || item["path"]
        current_assistant_blocks << tool_call_block(
          name: "FileChange",
          input: path,
          output: truncate_output(item["diff"] || item["content"]),
        )
        flush_assistant_blocks(messages, current_assistant_blocks)
      end
    end

    def extract_response_item_text(payload)
      content = payload["content"]
      case content
      when String then content
      when Array
        content.filter_map { |c|
          c["text"] if %w[output_text input_text text].include?(c["type"])
        }.join("\n")
      else
        payload["text"]
      end
    end

    def extract_message_text(item)
      content = item["content"]
      case content
      when String then content
      when Array
        content.filter_map { |c| c["text"] if c["type"] == "text" }.join("\n")
      else
        item["text"]
      end
    end

    # Extract meaningful text from tool output which may be a JSON wrapper.
    # Codex wraps some outputs as {"output":"...", "metadata":{...}} — either as Hash or JSON string.
    def extract_output_content(payload)
      raw = payload["output"] || payload["result"]
      unwrap_json_output(raw)
    end

    def unwrap_json_output(raw)
      case raw
      when Hash
        raw["output"].presence || raw["content"].presence || raw.to_json
      when String
        # Try to parse JSON strings that wrap the actual output
        if raw.strip.start_with?("{")
          begin
            parsed = JSON.parse(raw)
            return parsed["output"].presence || parsed["content"].presence || raw if parsed.is_a?(Hash)
          rescue JSON::ParserError
            # Not JSON, return as-is
          end
        end
        raw
      else
        raw&.to_json
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

    def flush_assistant_blocks(messages, blocks)
      return if blocks.empty?

      messages << build_message(role: "assistant", content_blocks: blocks.dup)
      blocks.clear
    end

    def extract_metadata(records, messages)
      # New format: session_meta
      session_meta = records.find { |r| r["type"] == "session_meta" }
      # Old format: thread.started
      started = records.find { |r| r["type"] == "thread.started" }

      meta_payload = session_meta&.dig("payload") || {}
      {
        "tool_name" => "codex",
        "session_id" => meta_payload["id"] || started&.dig("thread_id"),
        "start_time" => meta_payload["timestamp"] || session_meta&.dig("timestamp") || started&.dig("timestamp"),
        "model" => meta_payload.dig("model_provider"),
        "cli_version" => meta_payload["cli_version"],
        "total_messages" => messages.size,
      }.compact
    end
  end
end
