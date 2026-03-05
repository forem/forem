module AgentSessionParsers
  class Opencode < Base
    SUPPORTED_ROLES = %w[user assistant].freeze
    TOOL_STATUSES = Set.new(%w[pending running completed error]).freeze

    def parse
      data = JSON.parse(raw_content, max_nesting: MAX_JSON_NESTING)
      validate_export_shape!(data)

      messages = data.fetch("messages", []).filter_map do |entry|
        build_message_from_entry(entry)
      end

      metadata = extract_metadata(data, messages)
      build_result(messages: messages, metadata: metadata)
    end

    private

    def validate_export_shape!(data)
      return if data.is_a?(Hash) && data["info"].is_a?(Hash) && data["messages"].is_a?(Array)

      raise ArgumentError, "Invalid OpenCode export format"
    end

    def build_message_from_entry(entry)
      info = entry["info"] || {}
      role = info["role"]
      return unless SUPPORTED_ROLES.include?(role)

      blocks = build_blocks(entry["parts"] || [])
      blocks << text_block(format_assistant_error(info["error"])) if role == "assistant" && info["error"].present?
      return if blocks.empty?

      build_message(
        role: role,
        content_blocks: blocks,
        timestamp: format_time(info.dig("time", "created")),
        model: format_model(info),
      )
    end

    def build_blocks(parts) # rubocop:disable Metrics/CyclomaticComplexity
      parts.filter_map do |part|
        case part["type"]
        when "text"
          text_value = part["text"].to_s
          text_block(text_value) if text_value.present?
        when "reasoning"
          text_value = part["text"].to_s
          text_block("**Reasoning:** #{text_value}") if text_value.present?
        when "tool"
          build_tool_block(part)
        when "subtask"
          text_block(build_subtask_text(part))
        when "agent"
          text_block(build_agent_text(part))
        when "file"
          text_block(build_file_text(part))
        when "retry"
          text_block(build_retry_text(part))
        when "step-start"
          text_block("Step started")
        when "step-finish"
          text_block(build_step_finish_text(part))
        when "patch"
          text_block(build_patch_text(part))
        when "snapshot"
          snapshot = part["snapshot"].to_s
          text_block("Snapshot: `#{snapshot}`") if snapshot.present?
        when "compaction"
          text_block("Session compacted")
        end
      end
    end

    def build_tool_block(part)
      state = part["state"] || {}
      status = state["status"].to_s
      status = nil unless TOOL_STATUSES.include?(status)

      output = state["output"].presence || state["error"].presence
      output = truncate_output(output.to_json) if output.is_a?(Hash) || output.is_a?(Array)
      output = truncate_output(output) if output.is_a?(String)

      details = []
      details << "status=#{status}" if status
      details << state["title"] if state["title"].present?
      if state.dig("attachments")&.any?
        details << "attachments=#{state['attachments'].size}"
      end
      if details.any?
        output = [details.join(" | "), output.presence].compact.join("\n")
      end

      input = state["input"]
      input = input.to_json if input.is_a?(Hash) || input.is_a?(Array)
      input = input.to_s if input

      tool_call_block(
        name: part["tool"].presence || "tool",
        input: input&.truncate(200),
        output: output,
      )
    end

    def build_subtask_text(part)
      lines = ["Subtask: #{part['description'].presence || part['prompt'].presence || 'No description'}"]
      lines << "Prompt: #{part['prompt']}" if part["prompt"].present?
      if part["model"].is_a?(Hash)
        provider = part.dig("model", "providerID")
        model = part.dig("model", "modelID")
        lines << "Model: #{[provider, model].compact.join('/')}" if provider.present? || model.present?
      end
      lines.join("\n")
    end

    def build_agent_text(part)
      source = part.dig("source", "value")
      text = "Agent: #{part['name'].presence || 'delegation'}"
      text += "\n#{source}" if source.present?
      text
    end

    def build_file_text(part)
      bits = ["File: #{part['filename'].presence || 'attachment'}"]
      bits << "mime=#{part['mime']}" if part["mime"].present?
      bits << "source=#{part.dig('source', 'path')}" if part.dig("source", "path").present?
      bits.join(" | ")
    end

    def build_retry_text(part)
      name = part.dig("error", "name").presence || "Error"
      message = part.dig("error", "message").presence || "retry"
      "Retry attempt #{part['attempt']}: #{name} - #{message}"
    end

    def build_step_finish_text(part)
      reason = part["reason"].presence || "completed"
      "Step finished: #{reason}"
    end

    def build_patch_text(part)
      files = Array(part["files"])
      return "Patch applied" if files.empty?

      "Patch applied (#{files.size} files): #{files.join(', ')}"
    end

    def format_assistant_error(error)
      return if error.blank?

      if error.is_a?(Hash)
        [error["name"], error["message"], error["statusCode"]].compact.join(" - ").prepend("Assistant error: ")
      else
        "Assistant error: #{error}"
      end
    end

    def format_model(info)
      provider = info.dig("model", "providerID").presence || info["providerID"]
      model = info.dig("model", "modelID").presence || info["modelID"]
      return if provider.blank? && model.blank?

      [provider, model].compact.join("/")
    end

    def format_time(value)
      return if value.blank?

      Time.at(value.to_f / 1000).utc.iso8601
    rescue StandardError
      value.to_s
    end

    def extract_metadata(data, messages)
      info = data["info"] || {}

      {
        "tool_name" => "opencode",
        "session_id" => info["id"],
        "slug" => info["slug"],
        "version" => info["version"],
        "directory" => info["directory"],
        "share_url" => info.dig("share", "url"),
        "summary" => info["summary"],
        "todo_note" => "OpenCode export omits todos; support can be added in a future parser update.",
        "start_time" => format_time(info.dig("time", "created")),
        "end_time" => format_time(info.dig("time", "updated")),
        "model" => messages.filter_map { |m| m["model"] }.first,
        "total_messages" => messages.size
      }.compact
    end
  end
end
