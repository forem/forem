require "rails_helper"

RSpec.describe ContentRenderer do
  let(:markdown) { "hello, hey" }
  let(:renderer) { described_class.new(markdown, source: nil, user: nil, fixer: MarkdownProcessor::Fixer::FixAll) }

  it "calls fixer" do
    allow(MarkdownProcessor::Fixer::FixAll).to receive(:call).and_call_original
    described_class.new(markdown, source: nil, user: nil, fixer: MarkdownProcessor::Fixer::FixAll).process
    expect(MarkdownProcessor::Fixer::FixAll).to have_received(:call).with(markdown)
  end

  describe "#process" do
    let(:parser) { instance_double(MarkdownProcessor::Parser) }

    context "with double parser" do
      before do
        allow(MarkdownProcessor::Parser).to receive(:new).and_return(parser)
        allow(parser).to receive(:finalize)
        allow(parser).to receive(:calculate_reading_time).and_return(1)
      end

      it "calls finalize with link_attributes" do
        renderer.process(link_attributes: { rel: "nofollow" })
        finalize_attrs = {
          link_attributes: { rel: "nofollow" },
          prefix_images_options: { width: 800, synchronous_detail_detection: false }
        }
        expect(parser).to have_received(:finalize).with(finalize_attrs)
      end
    end
  end

  describe "#process_article" do
    it "calculates reading time if processing an article" do
      result = renderer.process_article
      expect(result.reading_time).to eq(1)
    end

    it "sets front_matter if it exists" do
      frontmatter_markdown = <<~HEREDOC
        ---
        title: Hello
        published: false
        description: Hello Hello
        ---
        lalalalala
      HEREDOC
      md_renderer = described_class.new(frontmatter_markdown, source: nil, user: nil,
                                                              fixer: MarkdownProcessor::Fixer::FixAll)
      result = md_renderer.process_article
      expect(result.front_matter["title"]).to eq("Hello")
      expect(result.front_matter["description"]).to eq("Hello Hello")
    end
  end

  context "when markdown is valid" do
    let(:markdown) { "# Hey\n\nI'm a markdown" }
    let(:expected_result) do
      "<h1>\n  <a name=\"hey\" href=\"#hey\">\n  </a>\n  Hey\n</h1>\n\n<p>I'm a markdown</p>\n\n"
    end

    it "processes markdown" do
      result = described_class.new(markdown, source: build(:comment), user: build(:user)).process
      expect(result.processed_html).to eq(expected_result)
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
      end.to raise_error(ContentRenderer::ContentParsingError, /This liquid tag can only be used in Articles/)
    end

    it "raises ContentParsingError for display ad" do
      source = build(:display_ad)
      expect do
        described_class.new(markdown, source: source, user: user).process
      end.to raise_error(ContentRenderer::ContentParsingError, /This liquid tag can only be used in Articles/)
    end
  end

  context "when markdown has invalid frontmatter" do
    let(:markdown) { "---\ntitle: Title\npublished: false\npublished_at:2022-12-05 18:00 +0300---\n\n" }

    it "raises ContentParsingError" do
      expect do
        described_class.new(markdown, source: nil, user: nil).process_article
      end.to raise_error(ContentRenderer::ContentParsingError, /while scanning a simple key/)
    end
  end
end
