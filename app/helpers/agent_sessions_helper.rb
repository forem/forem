module AgentSessionsHelper
  # rubocop:disable Layout/LineLength

  # Claude AI symbol path (from the official logo)
  CLAUDE_SYMBOL_PATH = "M 233.96 800.21 L 468.64 668.54 L 472.59 657.10 L 468.64 650.74 L 457.21 650.74 L 418 648.32 L 283.89 644.70 L 167.60 639.87 L 54.93 633.83 L 26.58 627.79 L 0 592.75 L 2.74 575.28 L 26.58 559.25 L 60.72 562.23 L 136.19 567.38 L 249.42 575.19 L 331.57 580.03 L 453.26 592.67 L 472.59 592.67 L 475.33 584.86 L 468.72 580.03 L 463.57 575.19 L 346.39 495.79 L 219.54 411.87 L 153.10 363.54 L 117.18 339.06 L 99.06 316.11 L 91.25 266.01 L 123.87 230.09 L 167.68 233.07 L 178.87 236.05 L 223.25 270.20 L 318.04 343.57 L 441.83 434.74 L 459.95 449.80 L 467.19 444.64 L 468.08 441.02 L 459.95 427.41 L 392.62 305.72 L 320.78 181.93 L 288.81 130.63 L 280.35 99.87 C 277.37 87.22 275.19 76.59 275.19 63.62 L 312.32 13.21 L 332.86 6.60 L 382.39 13.21 L 403.25 31.33 L 434.01 101.72 L 483.87 212.54 L 561.18 363.22 L 583.81 407.92 L 595.89 449.32 L 600.40 461.96 L 608.21 461.96 L 608.21 454.71 L 614.58 369.83 L 626.34 265.61 L 637.77 131.52 L 641.72 93.75 L 660.40 48.48 L 697.53 24 L 726.52 37.85 L 750.36 72 L 747.06 94.07 L 732.89 186.20 L 705.10 330.52 L 686.98 427.17 L 697.53 427.17 L 709.61 415.09 L 758.50 350.17 L 840.64 247.49 L 876.89 206.74 L 919.17 161.72 L 946.31 140.30 L 997.61 140.30 L 1035.38 196.43 L 1018.47 254.42 L 965.64 321.42 L 921.83 378.20 L 859.01 462.77 L 819.79 530.42 L 823.41 535.81 L 832.75 534.93 L 974.66 504.72 L 1051.33 490.87 L 1142.82 475.17 L 1184.21 494.50 L 1188.72 514.15 L 1172.46 554.34 L 1074.60 578.50 L 959.84 601.45 L 788.94 641.88 L 786.85 643.41 L 789.26 646.39 L 866.26 653.64 L 899.19 655.41 L 979.81 655.41 L 1129.93 666.60 L 1169.15 692.54 L 1192.67 724.27 L 1188.72 748.43 L 1128.32 779.19 L 1046.82 759.87 L 856.59 714.60 L 791.36 698.34 L 782.34 698.34 L 782.34 703.73 L 836.70 756.89 L 936.32 846.85 L 1061.07 962.82 L 1067.44 991.49 L 1051.41 1014.12 L 1034.50 1011.70 L 924.89 929.23 L 882.60 892.11 L 786.85 811.49 L 780.48 811.49 L 780.48 819.95 L 802.55 852.24 L 919.09 1027.41 L 925.13 1081.13 L 916.67 1098.60 L 886.47 1109.15 L 853.29 1103.11 L 785.07 1007.36 L 714.68 899.52 L 657.91 802.87 L 650.98 806.82 L 617.48 1167.70 L 601.77 1186.15 L 565.53 1200 L 535.33 1177.05 L 519.30 1139.92 L 535.33 1066.55 L 554.66 970.79 L 570.36 894.68 L 584.54 800.13 L 593 768.72 L 592.43 766.63 L 585.50 767.52 L 514.23 865.37 L 405.83 1011.87 L 320.05 1103.68 L 299.52 1111.81 L 263.92 1093.37 L 267.22 1060.43 L 287.11 1031.11 L 405.83 880.11 L 477.42 786.52 L 523.65 732.48 L 523.33 724.67 L 520.59 724.67 L 205.29 929.40 L 149.15 936.64 L 124.99 914.01 L 127.97 876.89 L 139.41 864.81 L 234.20 799.57 Z".freeze

  # OpenAI logo path (for Codex)
  OPENAI_SYMBOL_PATH = "M22.2819 9.8211a5.9847 5.9847 0 0 0-.5157-4.9108 6.0462 6.0462 0 0 0-6.5098-2.9A6.0651 6.0651 0 0 0 4.9807 4.1818a5.9847 5.9847 0 0 0-3.9977 2.9 6.0462 6.0462 0 0 0 .7427 7.0966 5.98 5.98 0 0 0 .511 4.9107 6.051 6.051 0 0 0 6.5146 2.9001A5.9847 5.9847 0 0 0 13.2599 24a6.0557 6.0557 0 0 0 5.7718-4.2058 5.9894 5.9894 0 0 0 3.9977-2.9001 6.0557 6.0557 0 0 0-.7475-7.0729zm-9.022 12.6081a4.4755 4.4755 0 0 1-2.8764-1.0408l.1419-.0804 4.7783-2.7582a.7948.7948 0 0 0 .3927-.6813v-6.7369l2.02 1.1686a.071.071 0 0 1 .038.052v5.5826a4.504 4.504 0 0 1-4.4945 4.4944zm-9.6607-4.1254a4.4708 4.4708 0 0 1-.5346-3.0137l.142.0852 4.783 2.7582a.7712.7712 0 0 0 .7806 0l5.8428-3.3685v2.3324a.0804.0804 0 0 1-.0332.0615L9.74 19.9502a4.4992 4.4992 0 0 1-6.1408-1.6464zM2.3408 7.8956a4.485 4.485 0 0 1 2.3655-1.9728V11.6a.7664.7664 0 0 0 .3879.6765l5.8144 3.3543-2.0201 1.1685a.0757.0757 0 0 1-.071 0l-4.8303-2.7865A4.504 4.504 0 0 1 2.3408 7.872zm16.5963 3.8558L13.1038 8.364 15.1192 7.2a.0757.0757 0 0 1 .071 0l4.8303 2.7913a4.4944 4.4944 0 0 1-.6765 8.1042v-5.6772a.79.79 0 0 0-.407-.667zm2.0107-3.0231l-.142-.0852-4.7735-2.7818a.7759.7759 0 0 0-.7854 0L9.409 9.2297V6.8974a.0662.0662 0 0 1 .0284-.0615l4.8303-2.7866a4.4992 4.4992 0 0 1 6.6802 4.66zM8.3065 12.863l-2.02-1.1638a.0804.0804 0 0 1-.038-.0567V6.0742a4.4992 4.4992 0 0 1 7.3757-3.4537l-.142.0805L8.704 5.459a.7948.7948 0 0 0-.3927.6813zm1.0976-2.3654l2.602-1.4998 2.6069 1.4998v2.9994l-2.5974 1.4997-2.6067-1.4997Z".freeze

  # Gemini sparkle/star icon path (from official Google Gemini branding)
  # GitHub Copilot icon paths (from primer/octicons copilot-24.svg)
  COPILOT_PATH_1 = "M23.922 16.992c-.861 1.495-5.859 5.023-11.922 5.023-6.063 0-11.061-3.528-11.922-5.023A.641.641 0 0 1 0 16.736v-2.869a.841.841 0 0 1 .053-.22c.372-.935 1.347-2.292 2.605-2.656.167-.429.414-1.055.644-1.517a10.195 10.195 0 0 1-.052-1.086c0-1.331.282-2.499 1.132-3.368.397-.406.89-.717 1.474-.952 1.399-1.136 3.392-2.093 6.122-2.093 2.731 0 4.767.957 6.166 2.093.584.235 1.077.546 1.474.952.85.869 1.132 2.037 1.132 3.368 0 .368-.014.733-.052 1.086.23.462.477 1.088.644 1.517 1.258.364 2.233 1.721 2.605 2.656a.832.832 0 0 1 .053.22v2.869a.641.641 0 0 1-.078.256ZM12.172 11h-.344a4.323 4.323 0 0 1-.355.508C10.703 12.455 9.555 13 7.965 13c-1.725 0-2.989-.359-3.782-1.259a2.005 2.005 0 0 1-.085-.104L4 11.741v6.585c1.435.779 4.514 2.179 8 2.179 3.486 0 6.565-1.4 8-2.179v-6.585l-.098-.104s-.033.045-.085.104c-.793.9-2.057 1.259-3.782 1.259-1.59 0-2.738-.545-3.508-1.492a4.323 4.323 0 0 1-.355-.508h-.016.016Zm.641-2.935c.136 1.057.403 1.913.878 2.497.442.544 1.134.938 2.344.938 1.573 0 2.292-.337 2.657-.751.384-.435.558-1.15.558-2.361 0-1.14-.243-1.847-.705-2.319-.477-.488-1.319-.862-2.824-1.025-1.487-.161-2.192.138-2.533.529-.269.307-.437.808-.438 1.578v.021c0 .265.021.562.063.893Zm-1.626 0c.042-.331.063-.628.063-.894v-.02c-.001-.77-.169-1.271-.438-1.578-.341-.391-1.046-.69-2.533-.529-1.505.163-2.347.537-2.824 1.025-.462.472-.705 1.179-.705 2.319 0 1.211.175 1.926.558 2.361.365.414 1.084.751 2.657.751 1.21 0 1.902-.394 2.344-.938.475-.584.742-1.44.878-2.497Z".freeze
  COPILOT_PATH_2 = "M14.5 14.25a1 1 0 0 1 1 1v2a1 1 0 0 1-2 0v-2a1 1 0 0 1 1-1Zm-5 0a1 1 0 0 1 1 1v2a1 1 0 0 1-2 0v-2a1 1 0 0 1 1-1Z".freeze

  # Pi logo paths (from shittycodingagent.ai/logo.svg)
  PI_P_PATH = "M165.29 165.29H517.36V400H400V517.36H282.65V634.72H165.29Z M282.65 282.65V400H400V282.65Z".freeze
  PI_DOT_PATH = "M517.36 400H634.72V634.72H517.36Z".freeze

  GEMINI_SYMBOL_PATH = "M32.447 0c.68 0 1.273.465 1.439 1.125a38.904 38.904 0 001.999 5.905c2.152 5 5.105 9.376 8.854 13.125 3.751 3.75 8.126 6.703 13.125 8.855a38.98 38.98 0 005.906 1.999c.66.166 1.124.758 1.124 1.438 0 .68-.464 1.273-1.125 1.439a38.902 38.902 0 00-5.905 1.999c-5 2.152-9.375 5.105-13.125 8.854-3.749 3.751-6.702 8.126-8.854 13.125a38.973 38.973 0 00-2 5.906 1.485 1.485 0 01-1.438 1.124c-.68 0-1.272-.464-1.438-1.125a38.913 38.913 0 00-2-5.905c-2.151-5-5.103-9.375-8.854-13.125-3.75-3.749-8.125-6.702-13.125-8.854a38.973 38.973 0 00-5.905-2A1.485 1.485 0 010 32.448c0-.68.465-1.272 1.125-1.438a38.903 38.903 0 005.905-2c5-2.151 9.376-5.104 13.125-8.854 3.75-3.749 6.703-8.125 8.855-13.125a38.972 38.972 0 001.999-5.905A1.485 1.485 0 0132.447 0z".freeze

  # rubocop:enable Layout/LineLength

  TOOL_INFO = {
    "claude_code" => { bg: "#D97706", label: "Claude Code" },
    "codex" => { bg: "#10A37F", label: "Codex" },
    "gemini_cli" => { bg: "#4285F4", label: "Gemini CLI" },
    "github_copilot" => { bg: "#333", label: "GitHub Copilot" },
    "opencode" => { bg: "#F97316", label: "OpenCode" },
    "cursor" => { bg: "#000", label: "Cursor" },
    "pi" => { bg: "#EF4444", label: "Pi" }
  }.freeze

  def agent_session_tool_icon(tool_name, show_label: true)
    info = TOOL_INFO[tool_name] || TOOL_INFO["claude_code"]
    background = info[:bg]
    label = info[:label]

    svg = build_tool_svg(tool_name, background)

    content_tag(:span, class: "agent-session-tool-icon-badge", title: label) do
      result = svg.html_safe # rubocop:disable Rails/OutputSafety
      result += content_tag(:span, label, class: "agent-session-tool-icon-label") if show_label
      result
    end
  end

  # rubocop:disable Layout/LineLength
  def build_tool_svg(tool_name, background)
    case tool_name
    when "claude_code"
      %(<svg width="20" height="20" viewBox="0 0 1200 1200" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><path d="#{CLAUDE_SYMBOL_PATH}" fill="#D97757"/></svg>)
    when "codex"
      %(<svg width="20" height="20" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><path d="#{OPENAI_SYMBOL_PATH}" fill="#10A37F"/></svg>)
    when "gemini_cli"
      %(<svg width="20" height="20" viewBox="0 0 65 65" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><defs><linearGradient id="gemini-g" x1="18" y1="43" x2="52" y2="15" gradientUnits="userSpaceOnUse"><stop stop-color="#4893FC"/><stop offset=".27" stop-color="#4893FC"/><stop offset=".777" stop-color="#969DFF"/><stop offset="1" stop-color="#BD99FE"/></linearGradient></defs><path d="#{GEMINI_SYMBOL_PATH}" fill="url(#gemini-g)"/></svg>)
    when "pi"
      %(<svg width="20" height="20" viewBox="0 0 800 800" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><rect width="800" height="800" rx="80" fill="#000"/><path fill="#fff" fill-rule="evenodd" d="#{PI_P_PATH}"/><path fill="#fff" d="#{PI_DOT_PATH}"/></svg>)
    when "github_copilot"
      %(<svg width="20" height="20" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><path d="#{COPILOT_PATH_1}" fill="#333"/><path d="#{COPILOT_PATH_2}" fill="#333"/></svg>)
    else
      abbr = tool_name_abbreviation(tool_name)
      %(<svg width="20" height="20" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" style="flex-shrink:0"><rect width="20" height="20" rx="4" fill="#{background}"/><text x="10" y="14" text-anchor="middle" fill="#fff" font-size="10" font-weight="700" font-family="system-ui,sans-serif">#{abbr}</text></svg>)
    end
  end
  # rubocop:enable Layout/LineLength

  def tool_name_abbreviation(tool_name)
    case tool_name
    when "gemini_cli" then "G"
    when "github_copilot" then "GH"
    when "opencode" then "OC"
    when "cursor" then "Cu"
    when "pi" then "Pi"
    else tool_name[0..1].upcase
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
    lexer ? ext : nil
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
