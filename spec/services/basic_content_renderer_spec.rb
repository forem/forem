require "rails_helper"

RSpec.describe BasicContentRenderer do
  let(:markdown) { "hello, hey" }

  it "calls fixer" do
    allow(MarkdownProcessor::Fixer::FixAll).to receive(:call).and_call_original
    described_class.new(markdown, source: nil, user: nil, fixer: MarkdownProcessor::Fixer::FixAll).process
    expect(MarkdownProcessor::Fixer::FixAll).to have_received(:call).with(markdown)
  end

  describe "#process" do
    let(:renderer) { described_class.new(markdown, source: nil, user: nil, fixer: MarkdownProcessor::Fixer::FixAll) }
    let(:parser) { instance_double(MarkdownProcessor::Parser) }

    before do
      allow(MarkdownProcessor::Parser).to receive(:new).and_return(parser)
      allow(parser).to receive(:finalize)
    end

    it "calls finalize with link_attributes" do
      renderer.process(link_attributes: { rel: "nofollow" })
      finalize_attrs = {
        link_attributes: { rel: "nofollow" },
        sanitize_options: {},
        prefix_images_options: { width: 800, synchronous_detail_detection: false }
      }
      expect(parser).to have_received(:finalize).with(finalize_attrs)
    end

    it "calls finalize with sanitize_options" do
      allow(MarkdownProcessor::Fixer::FixAll).to receive(:call).and_return("text")
      sanitize_options = { tags: %w[div] }
      # attrs = ["text", { source: nil, user: nil }]
      # expect(MarkdownProcessor::Parser).to have_received(:new).with(*attrs)
      finalize_attrs = {
        link_attributes: {},
        sanitize_options: sanitize_options,
        prefix_images_options: { width: 800, synchronous_detail_detection: false }
      }
      renderer.process(sanitize_options: { tags: %w[div] })
      expect(parser).to have_received(:finalize).with(finalize_attrs)
    end
  end

  context "when markdown is valid" do
    let(:markdown) { "# Hey\n\nI'm a markdown" }
    let(:expected_result) do
      "<h1>\n  <a name=\"hey\" href=\"#hey\" class=\"anchor\">\n  </a>\n  Hey\n</h1>\n\n<p>I'm a markdown</p>\n\n"
    end

    it "processes markdown" do
      result = described_class.new(markdown, source: build(:comment), user: build(:user)).process
      expect(result).to eq(expected_result)
    end
  end

  context "when markdown has liquid tags that aren't allowed for source" do
    let(:markdown) { "hello hey hey hey {% poll 123 %}" }
    let(:user) { instance_double(User) }

    before do
      allow(user).to receive(:any_admin?).and_return(true)
    end

    it "raises ContentParsingError for comment" do
      source = build(:comment)
      expect do
        described_class.new(markdown, source: source, user: user).process
      end.to raise_error(BasicContentRenderer::ContentParsingError, /This liquid tag can only be used in Articles/)
    end

    it "raises ContentParsingError for display ad" do
      source = build(:display_ad)
      expect do
        described_class.new(markdown, source: source, user: user).process
      end.to raise_error(BasicContentRenderer::ContentParsingError, /This liquid tag can only be used in Articles/)
    end
  end
end
