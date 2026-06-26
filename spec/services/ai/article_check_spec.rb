require "rails_helper"

RSpec.describe Ai::ArticleCheck, type: :service do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article, user: user) }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::Community).to receive(:community_description).and_return("A community for developers.")
  end

  describe "#spam?" do
    context "when AI responds successfully" do
      before do
        allow(ai_client).to receive(:call).and_return("YES")
      end

      it "returns true if spam" do
        result = described_class.new(article).spam?
        expect(result).to be(true)
      end
    end

    context "when AI responds NO" do
      before do
        allow(ai_client).to receive(:call).and_return("NO")
      end

      it "returns false if not spam" do
        result = described_class.new(article).spam?
        expect(result).to be(false)
      end
    end

    context "when article has tags with custom moderation instructions" do
      let(:tag_with_instructions) { create(:tag, name: "testtag", moderation_instructions: "Assure it does not contain spoilers.") }

      before do
        article.tags << tag_with_instructions
        allow(ai_client).to receive(:call).and_return("NO")
      end

      it "includes the custom moderation instructions in the prompt" do
        checker = described_class.new(article)
        prompt = checker.send(:build_prompt)
        expect(prompt).to include("Custom Tag Moderation Instructions:")
        expect(prompt).to include("- #testtag: Assure it does not contain spoilers.")
      end
    end
  end
end
