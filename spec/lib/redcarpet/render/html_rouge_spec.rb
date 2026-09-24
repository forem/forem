require "rails_helper"

RSpec.describe Redcarpet::Render::HTMLRouge do
  let(:renderer) { described_class.new(hard_wrap: true, filter_html: false) }
  let(:markdown) { Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG) }

  describe "mermaid code blocks" do
    it "renders a fenced mermaid block as a data-lang tagged pre" do
      output = markdown.render("```mermaid\ngraph TD;\nA-->B;\n```")

      expect(output).to include('<pre data-lang="mermaid"><code>')
      expect(output).to include("graph TD;")
      expect(output).not_to include("highlight")
    end

    it "matches the language hint case insensitively" do
      output = markdown.render("```Mermaid\ngraph TD;\nA-->B;\n```")

      expect(output).to include('<pre data-lang="mermaid"><code>')
    end

    it "escapes HTML in the diagram source" do
      output = markdown.render(%(```mermaid\ngraph TD\nA["<img src=x onerror=alert(1)>"]-->B\n```))

      expect(output).to include("&lt;img src=x onerror=alert(1)&gt;")
      expect(output).not_to include("<img")
    end

    it "leaves other languages syntax highlighted" do
      output = markdown.render("```ruby\nputs 'mermaid'\n```")

      expect(output).to include("highlight ruby")
      expect(output).not_to include('data-lang="mermaid"')
    end

    it "leaves a language that merely starts with mermaid syntax highlighted" do
      output = markdown.render("```mermaidjs\ngraph TD;\n```")

      expect(output).not_to include('data-lang="mermaid"')
      expect(output).to include("highlight")
    end

    it "falls back to a highlighted code block when the source exceeds the byte cap" do
      source = "graph TD\n#{"A-->B\n" * 4000}"
      output = markdown.render("```mermaid\n#{source}```")

      expect(output).not_to include('data-lang="mermaid"')
      expect(output).to include("highlight plaintext")
    end

    it "falls back to a highlighted code block when the source exceeds the line cap" do
      source = "graph TD\n#{"A-->B\n" * 600}"
      output = markdown.render("```mermaid\n#{source}```")

      expect(output).not_to include('data-lang="mermaid"')
      expect(output).to include("highlight plaintext")
    end

    it "falls back to a highlighted code block when the source is blank" do
      output = markdown.render("```mermaid\n\n```")

      expect(output).not_to include('data-lang="mermaid"')
      expect(output).to include("highlight plaintext")
    end

    it "falls back to a highlighted code block and logs when rendering raises" do
      allow(ERB::Util).to receive(:html_escape).and_raise(StandardError, "boom")
      allow(Rails.logger).to receive(:error)

      output = markdown.render("```mermaid\ngraph TD;\nA-->B;\n```")

      expect(output).not_to include('data-lang="mermaid"')
      expect(output).to include("highlight plaintext")
      expect(Rails.logger).to have_received(:error).with(/Mermaid block rendering failed/)
    end
  end
end
