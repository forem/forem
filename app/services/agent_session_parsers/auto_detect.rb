module AgentSessionParsers
  class AutoDetect
    PARSERS = {
      "claude_code" => ClaudeCode,
      "codex" => Codex,
      "gemini_cli" => GeminiCli,
      "pi" => Pi,
      "github_copilot" => GithubCopilot
    }.freeze

    def self.parser_for(tool_name)
      PARSERS.fetch(tool_name) do
        raise ArgumentError, "Unknown agent tool: #{tool_name}. Supported: #{PARSERS.keys.join(', ')}"
      end
    end

    def self.detect_and_parse(content, filename: nil)
      tool_name = detect_tool(content, filename: filename)
      parser = parser_for(tool_name)
      result = parser.parse(content)
      [tool_name, result]
    end

    def self.detect_tool(content, filename: nil) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Lint/UnusedMethodArgument
      # Try parsing first line as JSON
      first_line = content.lines.first&.strip
      if first_line&.start_with?("{")
        begin
          first_record = JSON.parse(first_line, max_nesting: 50)

          # GitHub Copilot: session.start with copilot producer
          return "github_copilot" if first_record["type"] == "session.start"

          # Codex: old format has dotted types, new format has session_meta
          return "codex" if first_record["type"]&.match?(/^(thread|turn|item|event_msg)\./)
          return "codex" if first_record["type"] == "session_meta"

          # Pi: first record is {type: "session", version: N}
          return "pi" if first_record["type"] == "session" && first_record.key?("version")

          # Gemini: has session_metadata type
          return "gemini_cli" if first_record["type"] == "session_metadata"

          # JSONL-based agents (Claude Code, Pi, etc.)
          if first_record.key?("sessionId") || first_record.key?("version") ||
              first_record.key?("parentId") || first_record.key?("parentUuid") ||
              first_record.key?("parentSession")
            return detect_jsonl_tool(content, first_record)
          end
        rescue JSON::ParserError
          # Not JSON, continue detection
        end
      end

      # Try full JSON parse (Gemini CLI uses single JSON object)
      begin
        data = JSON.parse(content, max_nesting: 50)
        return "gemini_cli" if data.is_a?(Hash) && !data.key?("parentId")
      rescue JSON::ParserError
        # Not JSON
      end

      # Default fallback
      "claude_code"
    end

    def self.detect_jsonl_tool(_content, first_record)
      # Pi uses id/parentId tree structure
      if first_record.key?("parentId") || first_record.key?("parentSession")
        return "pi"
      end

      # Claude Code uses parentUuid + sessionId
      if first_record.key?("parentUuid") || first_record.key?("sessionId")
        return "claude_code"
      end

      "claude_code" # Default for JSONL
    end
  end
end
