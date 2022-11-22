require "rails_helper"

RSpec.describe ContentRenderer do
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
