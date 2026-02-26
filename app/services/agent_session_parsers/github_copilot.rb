module AgentSessionParsers
  class GithubCopilot < Base
    def parse
      records = parse_jsonl_lines
      messages = []

      records.each do |record|
        case record["type"]
        when "user.message"
          text = record.dig("data", "content")
          messages << build_message(role: "user", content_blocks: [text_block(text)], timestamp: record["timestamp"]) if text.present?
        when "assistant.message"
          emit_assistant_message(record, messages)
        when "tool.execution_complete"
          data = record["data"] || {}
          output = extract_result_content(data["result"])
          formatted = truncate_output(output)
          attach_output_to_matching(messages, data["toolCallId"], formatted) if formatted.present?
        end
      end

      metadata = extract_metadata(records, messages)
      build_result(messages: messages, metadata: metadata)
    end

    private

    def emit_assistant_message(record, messages)
      data = record["data"] || {}
      content = data["content"]
      tool_requests = data["toolRequests"] || []

      # Emit text as its own message if present
      if content.present?
        messages << build_message(
          role: "assistant",
          content_blocks: [text_block(content)],
          timestamp: record["timestamp"],
        )
      end

      # Emit each tool request as its own message
      tool_requests.each do |tr|
        next if tr["name"] == "report_intent" # skip internal telemetry tool

        name = tr["name"] || "tool_call"
        input = tr["arguments"]
        input_str = input.is_a?(String) ? input.truncate(200) : input&.to_json&.truncate(200)

        messages << build_message(
          role: "assistant",
          content_blocks: [tool_call_block(name: name, input: input_str, output: nil, tool_call_id: tr["toolCallId"])],
          timestamp: record["timestamp"],
        )
      end
    end

    def tool_call_block(name:, input: nil, output: nil, tool_call_id: nil)
      block = super(name: name, input: input, output: output)
      block["tool_call_id"] = tool_call_id if tool_call_id
      block
    end

    # Copilot tool results come as {content: "...", detailedContent: "..."} hashes.
    # Prefer detailedContent (often contains diffs), fall back to content, then raw string.
    def extract_result_content(result)
      case result
      when Hash
        result["detailedContent"].presence || result["content"].presence || result.to_json
      when String
        result
      else
        result&.to_json
      end
    end

    def attach_output_to_matching(messages, tool_call_id, output)
      return unless tool_call_id

      messages.each do |m|
        next unless m["role"] == "assistant"

        m["content"]&.each do |b|
          if b["type"] == "tool_call" && b["tool_call_id"] == tool_call_id && b["output"].nil?
            b["output"] = output
            return
          end
        end
      end
    end

    def extract_metadata(records, messages)
      session_start = records.find { |r| r["type"] == "session.start" }
      data = session_start&.dig("data") || {}

      {
        "tool_name" => "github_copilot",
        "session_id" => data["sessionId"],
        "start_time" => data["startTime"] || session_start&.dig("timestamp"),
        "model" => records.find { |r| r["type"] == "tool.execution_complete" }&.dig("data", "model"),
        "cli_version" => data["copilotVersion"],
        "total_messages" => messages.size,
        "working_directory" => data.dig("context", "cwd"),
      }.compact
    end
  end
end
