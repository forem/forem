require "rails_helper"

RSpec.describe AgentSessionTag, type: :liquid_tag do
  let(:user) { create(:user) }
  let(:normalized_data) do
    {
      "messages" => [
        { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Fix the bug" }] },
        { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Done!" }] },
      ],
      "metadata" => { "tool_name" => "claude_code" }
    }
  end
  let(:agent_session) do
    AgentSession.create!(
      user: user,
      title: "Test Session",
      tool_name: "claude_code",
      normalized_data: normalized_data,
      published: true,
    )
  end

  def generate_tag(id, embedding_user: user)
    Liquid::Template.parse(
      "{% agent_session #{id} %}",
      { user: embedding_user },
    )
  end

  it "renders a valid agent session" do
    html = generate_tag(agent_session.id).render
    expect(html).to include("ltag-agent-session")
    expect(html).to include("Test Session")
    expect(html).to include("Claude Code")
    expect(html).to include("Fix the bug")
    expect(html).to include("Done!")
  end

  it "raises for non-existent session" do
    expect { generate_tag(999_999) }.to raise_error(StandardError, /not found/)
  end

  it "renders curated messages only" do
    agent_session.update!(curated_selections: [0])
    html = generate_tag(agent_session.id).render
    expect(html).to include("Fix the bug")
    expect(html).not_to include("Done!")
  end

  it "renders with range syntax" do
    html = Liquid::Template.parse("{% agent_session #{agent_session.id} 0..0 %}").render
    expect(html).to include("Fix the bug")
    expect(html).not_to include("Done!")
  end

  it "renders with named slice" do
    agent_session.update!(slices: [{ "name" => "intro", "indices" => [1] }])
    html = Liquid::Template.parse("{% agent_session #{agent_session.id} intro %}").render
    expect(html).to include("Done!")
    expect(html).not_to include("Fix the bug")
    expect(html).to include("intro")
  end

  it "raises for invalid syntax" do
    expect { Liquid::Template.parse("{% agent_session %}") }.to raise_error(StandardError, /Invalid/)
  end

  context "when session is unpublished" do
    let(:unpublished_session) do
      AgentSession.create!(
        user: user,
        title: "Draft Session",
        tool_name: "claude_code",
        normalized_data: normalized_data,
        published: false,
      )
    end

    it "allows the owner to embed their own unpublished session" do
      html = generate_tag(unpublished_session.id, embedding_user: user).render
      expect(html).to include("ltag-agent-session")
      expect(html).to include("Draft Session")
    end

    it "raises when a non-owner tries to embed an unpublished session" do
      other_user = create(:user)
      expect do
        generate_tag(unpublished_session.id, embedding_user: other_user)
      end.to raise_error(StandardError, /owner/)
    end

    it "raises when no user context is provided for an unpublished session" do
      expect do
        Liquid::Template.parse("{% agent_session #{unpublished_session.id} %}")
      end.to raise_error(StandardError, /owner/)
    end
  end

  it "allows any user to embed a published session" do
    other_user = create(:user)
    html = generate_tag(agent_session.id, embedding_user: other_user).render
    expect(html).to include("ltag-agent-session")
    expect(html).to include("Test Session")
  end

  it "renders when referenced by slug" do
    html = generate_tag(agent_session.slug).render
    expect(html).to include("ltag-agent-session")
    expect(html).to include("Test Session")
  end

  it "renders with slug and slice syntax" do
    agent_session.update!(slices: [{ "name" => "setup", "indices" => [0] }])
    html = Liquid::Template.parse("{% agent_session #{agent_session.slug} setup %}").render
    expect(html).to include("Fix the bug")
    expect(html).not_to include("Done!")
  end

  it "renders tool calls with toggle" do
    session_with_tools = AgentSession.create!(
      user: user,
      title: "Tool Session",
      tool_name: "claude_code",
      published: true,
      normalized_data: {
        "messages" => [
          {
            "index" => 0, "role" => "assistant",
            "content" => [
              { "type" => "tool_call", "name" => "Read", "input" => "/src/app.js", "output" => "code" },
            ]
          },
        ],
        "metadata" => {}
      },
    )

    html = generate_tag(session_with_tools.id).render
    expect(html).to include("agent-session-tool-toggle")
    expect(html).to include("Read")
    expect(html).to include("/src/app.js")
  end
end
