require "rails_helper"

RSpec.describe AgentSessionsHelper do
  describe "#agent_session_tool_icon" do
    it "renders the configured badge and label for every known tool", :aggregate_failures do
      described_class::TOOL_INFO.each do |tool_key, info|
        html = helper.agent_session_tool_icon(tool_key)
        expect(html).to include(%(title="#{info[:label]}"))
        expect(html).to include(%(<span class="agent-session-tool-icon-label">#{info[:label]}</span>))
      end
    end

    it "falls back to Claude Code when tool_name is unknown or nil", :aggregate_failures do
      expect(helper.agent_session_tool_icon("unknown_agent")).to include('title="Claude Code"')
      expect(helper.agent_session_tool_icon(nil)).to include('title="Claude Code"')
    end

    it "omits the label span when show_label is false" do
      html = helper.agent_session_tool_icon("antigravity_cli", show_label: false)
      expect(html).to include('title="Antigravity CLI"')
      expect(html).not_to include("agent-session-tool-icon-label")
    end
  end

  describe "#render_tool_input" do
    it "returns an empty html_safe string for nil or blank input", :aggregate_failures do
      expect(helper.render_tool_input("Read", nil)).to eq("")
      expect(helper.render_tool_input("Read", nil)).to be_html_safe
      expect(helper.render_tool_input("Read", "   \n\t  ")).to eq("")
    end

    it "renders shell tools as terminal blocks with a '$ ' prefix and escaped HTML", :aggregate_failures do
      %w[Bash bash execute_command exec_command shell run_command run_terminal_command execute terminal].each do |tool|
        html = helper.render_tool_input(tool, "echo '<script>alert(1)</script>' && ls")
        expect(html).to include('class="agent-session-pre agent-session-terminal"')
        expect(html).to include("$ echo &#39;&lt;script&gt;alert(1)&lt;/script&gt;&#39; &amp;&amp; ls")
        expect(html).not_to include("<script>")
      end
    end

    it "detects the language from the file path for file operation tools", :aggregate_failures do
      html = helper.render_tool_input("read_file", "app/models/user.rb\ndef hello\n  42\nend")
      expect(html).to include('class="agent-session-pre highlight ruby"')
      expect(html).to include('<span class="k">def</span>')

      ts_html = helper.render_tool_input("EditFile", "src/components/App.tsx")
      expect(ts_html).to include('class="agent-session-pre highlight tsx"')
    end

    it "highlights patch tools as diff", :aggregate_failures do
      %w[apply_patch apply_diff patch].each do |tool|
        html = helper.render_tool_input(tool, "--- a/foo.rb\n+++ b/foo.rb\n@@ -1 +1 @@\n-old\n+new\n")
        expect(html).to include('class="agent-session-pre highlight diff"')
        expect(html).to include('<span class="gd">-old</span>')
        expect(html).to include('<span class="gi">+new</span>')
      end
    end

    it "detects and pretty-prints valid JSON input when tool has no path language", :aggregate_failures do
      html = helper.render_tool_input("mcp_call", '{"key":"value","nested":[1,true]}')
      expect(html).to include('class="agent-session-pre highlight json"')
      expect(html).to include('<span class="nl">&quot;key&quot;</span>').or include('<span class="nl">"key"</span>')
      expect(html).to include("\n")
    end

    it "falls back to escaped plain pre/code when JSON is malformed or unrecognized", :aggregate_failures do
      html = helper.render_tool_input("mcp_call", "{not valid json <script>}")
      expect(html).to eq('<pre class="agent-session-pre"><code>{not valid json &lt;script&gt;}</code></pre>')
    end

    it "detects unified diff content even for generic tool names", :aggregate_failures do
      diff_samples = [
        "--- a/file.rb\n+++ b/file.rb",
        "diff --git a/file.rb b/file.rb\nindex 123..456",
        "some header\n@@ -10,4 +10,5 @@\n+added line",
      ]

      diff_samples.each do |sample|
        html = helper.render_tool_input("custom_tool", sample)
        expect(html).to include('class="agent-session-pre highlight diff"')
      end
    end

    it "sanitizes unexpected HTML tags from highlighted output as defense-in-depth" do
      allow(ForemNative).to receive(:syntax_highlight_html).and_return(
        '<span class="k" onclick="evil()">def</span><script>alert(1)</script>',
      )

      html = helper.render_tool_input("Read", "test.rb")
      expect(html).to include('<span class="k">def</span>')
      expect(html).not_to include("onclick")
      expect(html).not_to include("<script>")
    end

    it "rescues unexpected errors and falls back to escaped plain code" do
      allow(ForemNative).to receive(:syntax_highlight_html).and_raise(StandardError, "unexpected failure")

      html = helper.render_tool_input("Read", "test.rb <tag>")
      expect(html).to eq('<pre class="agent-session-pre"><code>test.rb &lt;tag&gt;</code></pre>')
    end
  end

  describe "#render_tool_output" do
    it "returns an empty html_safe string for nil or blank output", :aggregate_failures do
      expect(helper.render_tool_output("Read", "app/models/user.rb", nil)).to eq("")
      expect(helper.render_tool_output("Read", "app/models/user.rb", "")).to be_html_safe
      expect(helper.render_tool_output("Read", "app/models/user.rb", "   ")).to eq("")
    end

    it "highlights file tool output using the language inferred from input_text path", :aggregate_failures do
      html = helper.render_tool_output(
        "read_file",
        "gems/forem_native/src/lib.rs",
        "pub fn add(a: i32, b: i32) -> i32 { a + b }",
      )
      expect(html).to include('class="agent-session-pre highlight rust"')
      expect(html).to include('<span class="k">pub</span>')
      expect(html).to include('<span class="k">fn</span>')
    end

    it "falls back to content detection when a file path lacks an extension or is dotfiles-only",
       :aggregate_failures do
      json_out = helper.render_tool_output("read_file", ".eslintrc", '{"rules":{"semi":"error"}}')
      expect(json_out).to include('class="agent-session-pre highlight json"')

      plain_out = helper.render_tool_output("read_file", "dir/..rb", "plain output <tag>")
      expect(plain_out).to eq('<pre class="agent-session-pre"><code>plain output &lt;tag&gt;</code></pre>')
    end

    it "pretty-prints and highlights JSON output from shell or generic tools" do
      html = helper.render_tool_output("bash", "curl api", '[{"id":1}]')
      expect(html).to include('class="agent-session-pre highlight json"')
      expect(html).to include('<span class="mi">1</span>')
    end

    it "rescues unexpected errors in render_tool_output and escapes output_text" do
      allow(ForemNative).to receive(:syntax_highlight_html).and_raise(StandardError, "boom")

      html = helper.render_tool_output("read_file", "user.rb", "puts '<unsafe>'")
      expect(html).to eq('<pre class="agent-session-pre"><code>puts &#39;&lt;unsafe&gt;&#39;</code></pre>')
    end
  end
end
