module AgentSessionParsers
  class GeminiCli < Base
    def parse
      data = parse_data
      messages = []

      entries = extract_entries(data)
      entries.each do |entry|
        role = normalize_role(entry["type"] || entry["role"])
        next unless role

        if role == "user"
          blocks = extract_content_blocks(entry)
          messages << build_message(role: "user", content_blocks: blocks, timestamp: entry["timestamp"]) if blocks.any?
        else
          emit_assistant_messages(entry, messages)
        end
      end

      metadata = extract_metadata(data, messages)
      build_result(messages: messages, metadata: metadata)
    end

    private

    def parse_data
      # Try JSON first, then JSONL
      JSON.parse(raw_content, max_nesting: 50)
    rescue JSON::ParserError
      # JSONL format
      parse_jsonl_lines
    end

    def extract_entries(data)
      case data
      when Array
        data
      when Hash
        data["messages"] || data["entries"] || data.fetch("conversation", [])
      else
        []
      end
    end

    def normalize_role(type)
      case type&.downcase
      when "user", "human" then "user"
      when "gemini", "model", "assistant" then "assistant"
      end
    end

    # Gemini CLI JSON: each assistant entry can have content (text), thoughts, and toolCalls.
    # We split these into separate messages: one text message, then one message per tool call.
    def emit_assistant_messages(entry, messages)
      text_blocks = []

      # Extract thoughts as text (bold subject lines)
      thoughts = entry["thoughts"]
      if thoughts.is_a?(Array) && thoughts.any?
        summary = thoughts.map { |t| "**#{t['subject']}**" }.join(" / ")
        text_blocks << text_block(summary)
      end

      # Extract main content text
      content_blocks = extract_content_blocks(entry)
      text_blocks.concat(content_blocks.select { |b| b["type"] == "text" })

      # Emit text message if any text content
      if text_blocks.any?
        messages << build_message(
          role: "assistant",
          content_blocks: text_blocks,
          timestamp: entry["timestamp"],
        )
      end

      # Emit each tool call as its own message
      tool_calls = entry["toolCalls"]
      if tool_calls.is_a?(Array)
        tool_calls.each do |tc|
          name = tc["displayName"] || tc["name"] || "tool_call"
          input = tc["args"]
          input_str = input.is_a?(String) ? input.truncate(200) : input&.to_json&.truncate(200)

          # Extract output from the result structure
          output = extract_tool_output(tc)

          messages << build_message(
            role: "assistant",
            content_blocks: [tool_call_block(name: name, input: input_str, output: output)],
            timestamp: tc["timestamp"] || entry["timestamp"],
          )
        end
      end

      # Also handle inline functionCall/functionResponse in content arrays (Gemini API format)
      if content_blocks.any? { |b| b["type"] == "tool_call" }
        content_blocks.select { |b| b["type"] == "tool_call" }.each do |tc_block|
          messages << build_message(
            role: "assistant",
            content_blocks: [tc_block],
            timestamp: entry["timestamp"],
          )
        end
      end
    end

    def extract_tool_output(tc)
      # Gemini CLI format: result is an array of {functionResponse: {response: {output: "..."}}}
      result = tc["result"]
      return nil unless result.is_a?(Array)

      outputs = result.filter_map do |r|
        r.dig("functionResponse", "response", "output")
      end
      return nil if outputs.empty?

      truncate_output(outputs.join("\n"))
    end

    def extract_content_blocks(entry)
      blocks = []
      content = entry["content"] || entry["parts"] || entry["text"]

      case content
      when String
        blocks << text_block(content) if content.present?
      when Array
        content.each do |part|
          case part
          when String
            blocks << text_block(part)
          when Hash
            if part["text"]
              blocks << text_block(part["text"])
            elsif part["functionCall"] || part["tool_call"]
              call = part["functionCall"] || part["tool_call"]
              blocks << tool_call_block(
                name: call["name"],
                input: call["args"]&.to_json&.truncate(200),
              )
            elsif part["functionResponse"] || part["tool_result"]
              resp = part["functionResponse"] || part["tool_result"]
              blocks << tool_call_block(
                name: resp["name"],
                output: truncate_output(resp["response"]&.to_json || resp["content"]),
              )
            end
          end
        end
      end
      blocks
    end

    def extract_metadata(data, messages)
      meta = if data.is_a?(Hash)
               data["metadata"] || data["session_metadata"] || {}
             else
               {}
             end
      session_id = data.is_a?(Hash) ? (data["sessionId"] || meta["session_id"]) : meta["session_id"]
      start_time = data.is_a?(Hash) ? (data["startTime"] || meta["start_time"] || meta["timestamp"]) : nil
      model = data.is_a?(Hash) ? data.dig("messages", 0, "model") : nil

      {
        "tool_name" => "gemini_cli",
        "session_id" => session_id,
        "start_time" => start_time,
        "model" => model,
        "total_messages" => messages.size,
      }.compact
    end
  end
end
