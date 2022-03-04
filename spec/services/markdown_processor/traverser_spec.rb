require "rails_helper"

RSpec.describe MarkdownProcessor::Traverser, type: :service do
  let(:codeblock_markdown) do
    <<~HEREDOC
      ```
      This is a sample codeblock
      ```
    HEREDOC
  end

  describe "#each" do
    it "yields lines" do
      expected_results = ["```\n", "This is a sample codeblock\n", "```\n"]
      traverser = described_class.new(codeblock_markdown)
      results = []
      traverser.each { |line| results << line }
      expect(results).to eq(expected_results)
    end
  end

  describe "#in_codeblock?" do
    it "returns true if the line is in a codeblock" do
      expected_results = [false, true, false]
      traverser = described_class.new(codeblock_markdown)
      results = []
      traverser.each { |_line| results << traverser.in_codeblock? }
      expect(results).to eq(expected_results)
    end
  end
end
