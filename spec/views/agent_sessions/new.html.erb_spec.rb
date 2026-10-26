require "rails_helper"

RSpec.describe "agent_sessions/new" do
  # Tools with no session file to upload (e.g. Antigravity CLI stores
  # conversations in SQLite) only come in through the API.
  let(:api_only_tool_names) { %w[antigravity_cli] }

  it "renders a manual upload option for every supported agent tool" do
    render

    options = Capybara.string(rendered).all("select#session-tool option").map { |option| option[:value] }

    expect(options).to include("auto")
    expect(options).to include(*(AgentSession::TOOL_NAMES - api_only_tool_names))
    expect(options).not_to include(*api_only_tool_names)
  end

  it "renders session file location help for every supported agent tool" do
    render

    help_text = Capybara.string(rendered).find(".agent-session-paths", visible: false).text(:all)

    expect(help_text).to include("Claude Code")
    expect(help_text).to include("Codex (OpenAI)")
    expect(help_text).to include("Gemini CLI")
    expect(help_text).to include("GitHub Copilot")
    expect(help_text).to include("OpenCode")
    expect(help_text).to include("opencode export <session-id> > opencode-session.json")
    expect(help_text).to include("Pi")
  end

  it "renders OpenCode as the upload option label" do
    render

    option = Capybara.string(rendered).find("select#session-tool option[value='opencode']")
    expect(option.text).to eq("OpenCode")
  end
end
