module AgentSessionsHelper
  TOOL_INFO = {
    "claude_code" => { bg: "#D97706", label: "Claude Code", svg: "agent-claude-code.svg" },
    "codex" => { bg: "#10A37F", label: "Codex", svg: "agent-codex.svg" },
    "gemini_cli" => { bg: "#4285F4", label: "Gemini CLI", svg: "agent-gemini-cli.svg" },
    "github_copilot" => { bg: "#333", label: "GitHub Copilot", svg: "agent-github-copilot.svg" },
    "opencode" => { bg: "#F59E0B", label: "OpenCode", svg: "agent-opencode.svg" },
    "pi" => { bg: "#EF4444", label: "Pi", svg: "agent-pi.svg" }
  }.freeze

  def agent_session_tool_icon(tool_name, show_label: true)
    info = TOOL_INFO[tool_name] || TOOL_INFO["claude_code"]
    label = info[:label]

    content_tag(:span, class: "agent-session-tool-icon-badge", title: label) do
      result = inline_svg_tag(info[:svg], class: "agent-session-tool-svg", aria_hidden: true,
                                          width: 20, height: 20)
      result += content_tag(:span, label, class: "agent-session-tool-icon-label") if show_label
      result
    end
  end

  # Render a tool call input as a syntax-highlighted <pre> block.
  # rubocop:disable Rails/OutputSafety
  def render_tool_input(tool_name, input_text)
    return "".html_safe if input_text.blank?

    is_shell = SHELL_TOOL_NAMES.include?(tool_name.to_s)
    lang = is_shell ? nil : detect_tool_language(tool_name, input_text, input_text)
    code = lang == "json" ? pretty_print_json(input_text) : input_text

    if lang
      highlighted = rouge_highlight(code, lang)
      content_tag(:pre, class: "agent-session-pre highlight #{lang}") { content_tag(:code, highlighted.html_safe) }
    else
      css = is_shell ? "agent-session-pre agent-session-terminal" : "agent-session-pre"
      body = is_shell ? "$ #{h(input_text)}" : h(input_text)
      content_tag(:pre, class: css) { content_tag(:code, body.html_safe) }
    end
  rescue StandardError
    content_tag(:pre, class: "agent-session-pre") { content_tag(:code, h(input_text)) }
  end

  # Render a tool call output as a syntax-highlighted <pre> block.
  def render_tool_output(tool_name, input_text, output_text)
    return "".html_safe if output_text.blank?

    lang = detect_output_language(tool_name, input_text, output_text)
    code = lang == "json" ? pretty_print_json(output_text) : output_text

    if lang
      highlighted = rouge_highlight(code, lang)
      content_tag(:pre, class: "agent-session-pre highlight #{lang}") { content_tag(:code, highlighted.html_safe) }
    else
      content_tag(:pre, class: "agent-session-pre") { content_tag(:code, h(output_text)) }
    end
  rescue StandardError
    content_tag(:pre, class: "agent-session-pre") { content_tag(:code, h(output_text)) }
  end
  # rubocop:enable Rails/OutputSafety

  private

  FILE_TOOL_NAMES = Set.new(
    %w[
      Read Write Edit read_file write_file edit_file
      ReadFile WriteFile EditFile readFile writeFile editFile
      ReadFolder read write edit view_file view cat
    ],
  ).freeze

  SHELL_TOOL_NAMES = Set.new(
    %w[
      Bash bash execute_command exec_command shell run_command
      run_terminal_command execute terminal
    ],
  ).freeze

  PATCH_TOOL_NAMES = Set.new(
    %w[apply_patch apply_diff patch],
  ).freeze

  def detect_tool_language(tool_name, input_text, content)
    name = tool_name.to_s

    # File operation tools — detect language from the file path in input
    if FILE_TOOL_NAMES.include?(name)
      lang = language_from_path(input_text)
      return lang if lang
    end

    # Patch/diff tools — always render as diff
    return "diff" if PATCH_TOOL_NAMES.include?(name)

    # Content-based detection fallback
    detect_language_from_content(content)
  end

  def detect_output_language(tool_name, input_text, output_text)
    name = tool_name.to_s

    # File operation tools — detect language from the file path in input
    if FILE_TOOL_NAMES.include?(name)
      lang = language_from_path(input_text)
      return lang if lang
    end

    # Patch/diff tools — always render as diff
    return "diff" if PATCH_TOOL_NAMES.include?(name)

    # Content-based detection fallback (works for shell output that looks like JSON/diff)
    detect_language_from_content(output_text)
  end

  def rouge_highlight(code, lang)
    lexer = Rouge::Lexer.find(lang) || Rouge::Lexers::PlainText.new
    formatter = Rouge::Formatters::HTML.new
    html = formatter.format(lexer.lex(code))
    # Sanitize to only allow <span> with class attribute (defense in depth)
    sanitizer = Rails::HTML5::SafeListSanitizer.new
    sanitizer.sanitize(html, tags: %w[span], attributes: %w[class])
  end

  def language_from_path(path)
    return if path.blank?

    # Input might contain extra text; grab the first path-like token
    token = path.to_s.strip.split(/\s/).first
    ext = File.extname(token.to_s).delete_prefix(".")
    return if ext.blank?

    # Try Rouge lexer lookup
    lexer = Rouge::Lexer.find_fancy(ext) || Rouge::Lexer.find(ext)
    lexer&.tag
  rescue StandardError
    nil
  end

  def detect_language_from_content(content)
    return if content.blank?

    stripped = content.strip

    # Diff detection
    return "diff" if stripped.match?(/\A(---|\+\+\+|diff --git)\s/) ||
      stripped.match?(/^@@\s.*@@/m)

    # JSON detection
    if stripped.start_with?("{", "[")
      begin
        JSON.parse(stripped, max_nesting: 50)
        return "json"
      rescue JSON::ParserError
        # not valid JSON
      end
    end

    nil
  end

  def pretty_print_json(content)
    parsed = JSON.parse(content.strip, max_nesting: 50)
    JSON.pretty_generate(parsed)
  rescue JSON::ParserError
    content
  end
end
