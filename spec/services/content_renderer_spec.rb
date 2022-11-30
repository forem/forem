require "rails_helper"

RSpec.describe ContentRenderer do
  describe "#finalize" do
    let(:markdown) { "hello, hey" }
    let(:expected_result) { "<p>hello, hey</p>\n\n" }
    let(:mock_fixer) { class_double MarkdownProcessor::Fixer::FixAll }
    let(:mock_front_matter_parser) { instance_double FrontMatterParser::Parser }
    let(:mock_processor) { class_double MarkdownProcessor::Parser }
    let(:fixed_markdown) { :fixed_markdown }
    let(:parsed_contents) { Struct.new(:content).new(:parsed_content) }
    let(:processed_contents) { instance_double MarkdownProcessor::Parser }

    # rubocop:disable RSpec/InstanceVariable
    before do
      allow(mock_fixer).to receive(:call).and_return(fixed_markdown)
      allow(mock_front_matter_parser).to receive(:call).with(fixed_markdown).and_return(parsed_contents)
      allow(mock_processor).to receive(:new).and_return(processed_contents)
      allow(processed_contents).to receive(:finalize).and_return(expected_result)

      @original_fixer = described_class.fixer
      @original_parser = described_class.front_matter_parser
      @original_processor = described_class.processor

      described_class.fixer = mock_fixer
      described_class.front_matter_parser = mock_front_matter_parser
      described_class.processor = mock_processor
    end

    after do
      described_class.fixer = @original_fixer
      described_class.front_matter_parser = @original_parser
      described_class.processor = @original_processor
    end
    # rubocop:enable RSpec/InstanceVariable

    it "is the result of fixing, parsing, and processing" do
      result = described_class.new(markdown, source: nil, user: nil).finalize
      expect(result).to eq(expected_result)
      expect(mock_fixer).to have_received(:call)
      expect(mock_front_matter_parser).to have_received(:call).with(fixed_markdown)
      expect(mock_processor).to have_received(:new)
      expect(processed_contents).to have_received(:finalize)
    end
  end

  context "when markdown is valid" do
    let(:markdown) { "# Hey\n\nHi, hello there, what's up?" }
    let(:expected_result) { <<~RESULT }
      <h1>
        <a name="hey" href="#hey">
        </a>
        Hey
      </h1>

      <p>Hi, hello there, what's up?</p>

    RESULT

    it "processes markdown" do
      result = described_class.new(markdown, source: nil, user: nil).finalize
      expect(result).to eq(expected_result)
    end
  end

  context "when markdown has liquid tags that aren't allowed for user" do
    let(:markdown) { "hello hey hey hey {% poll 123 %}" }
    let(:article) { build(:article) }
    let(:user) { instance_double(User) }

    before do
      allow(user).to receive(:any_admin?).and_return(false)
    end

    it "raises ContentParsingError" do
      expect do
        described_class.new(markdown, source: article, user: user).finalize
      end.to raise_error(ContentRenderer::ContentParsingError, /User is not permitted to use this liquid tag/)
    end
  end

  context "when markdown has liquid tags that aren't allowed for source" do
    let(:markdown) { "hello hey hey hey {% poll 123 %}" }
    let(:source) { build(:comment) }
    let(:user) { instance_double(User) }

    before do
      allow(user).to receive(:any_admin?).and_return(true)
    end

    it "raises ContentParsingError" do
      expect do
        described_class.new(markdown, source: source, user: user).finalize
      end.to raise_error(ContentRenderer::ContentParsingError, /This liquid tag can only be used in Articles/)
    end
  end

  context "when markdown has invalid frontmatter" do
    let(:markdown) { "---\ntitle: Title\npublished: false\npublished_at:2022-12-05 18:00 +0300---\n\n" }

    it "raises ContentParsingError" do
      expect do
        described_class.new(markdown, source: nil, user: nil).front_matter
      end.to raise_error(ContentRenderer::ContentParsingError, /while scanning a simple key/)
    end
  end
end
