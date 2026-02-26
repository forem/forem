module AgentSessionParsers
  class ClaudeCode < Base
    def parse
      records = parse_jsonl_lines
      conversation_records = records.select { |r| r["type"].in?(%w[user assistant]) }

      messages = []
      tool_results_map = build_tool_results_map(conversation_records)

      conversation_records.each do |record|
        msg = record["message"]
        next unless msg

        role = msg["role"]
        timestamp = record["timestamp"]
        raw_content_blocks = msg["content"]

        case role
        when "user"
          content_blocks = parse_user_content(raw_content_blocks)
          next if content_blocks.empty? # Skip tool-result-only messages

          messages << build_message(role: "user", content_blocks: content_blocks, timestamp: timestamp)
        when "assistant"
          content_blocks = parse_assistant_content(raw_content_blocks, tool_results_map)
          next if content_blocks.empty?

          messages << build_message(role: "assistant", content_blocks: content_blocks, timestamp: timestamp)
        end
      end

      metadata = extract_metadata(records, messages)
      build_result(messages: messages, metadata: metadata)
    end

    private

    def build_tool_results_map(records)
      map = {}
      records.each do |record|
        next unless record.dig("message", "role") == "user"

        content = record.dig("message", "content")
        next unless content.is_a?(Array)

        content.each do |block|
          next unless block["type"] == "tool_result"

          tool_use_id = block["tool_use_id"]
          result_content = extract_tool_result_content(block)
          map[tool_use_id] = result_content
        end
      end
      map
    end

    def extract_tool_result_content(block)
      content = block["content"]
      case content
      when String
        truncate_output(content)
      when Array
        content.filter_map { |c| c["text"] if c["type"] == "text" }
          .join("\n")
          .then { |text| truncate_output(text) }
      else
        ""
      end
    end

    def parse_user_content(raw_content)
      case raw_content
      when String
        [text_block(raw_content)]
      when Array
        blocks = []
        raw_content.each do |block|
          case block["type"]
          when "text"
            blocks << text_block(block["text"])
          # Skip tool_result blocks — they're merged into assistant messages
          end
        end
        blocks
      else
        []
      end
    end

    def parse_assistant_content(raw_content, tool_results_map)
      return [] unless raw_content.is_a?(Array)

      blocks = []
      raw_content.each do |block|
        case block["type"]
        when "text"
          blocks << text_block(block["text"])
        when "tool_use"
          result = tool_results_map[block["id"]]
          input_summary = summarize_tool_input(block["name"], block["input"])
          blocks << tool_call_block(
            name: block["name"],
            input: input_summary,
            output: result,
          )
        # Skip "thinking" blocks by default
        end
      end
      blocks
    end

    def summarize_tool_input(name, input)
      return nil unless input.is_a?(Hash)

      case name
      when "Read"
        input["file_path"]
      when "Write"
        input["file_path"]
      when "Edit"
        input["file_path"]
      when "Bash"
        input["command"]
      when "Glob"
        input["pattern"]
      when "Grep"
        "#{input['pattern']} #{input['path']}".strip
      when "Task"
        input["description"] || input["prompt"]&.truncate(100)
      else
        input.to_json.truncate(200)
      end
    end

    def extract_metadata(records, messages)
      first_record = records.find { |r| r["type"].in?(%w[user assistant]) }
      last_record = records.reverse.find { |r| r["type"].in?(%w[user assistant]) }

      {
        "tool_name" => "claude_code",
        "session_id" => first_record&.dig("sessionId"),
        "start_time" => first_record&.dig("timestamp"),
        "end_time" => last_record&.dig("timestamp"),
        "total_messages" => messages.size,
        "working_directory" => first_record&.dig("cwd"),
        "git_branch" => first_record&.dig("gitBranch"),
        "model" => records.find { |r| r.dig("message", "model") }&.dig("message", "model"),
      }.compact
    end
  end
end
