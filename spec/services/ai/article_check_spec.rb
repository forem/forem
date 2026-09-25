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

  describe "#spam? with Jev selected" do
    before { enable_jev_for(:article_spam_check) }

    it "sends one batched request of narrow questions instead of calling Gemini" do
      requests = stub_jev

      expect(described_class.new(article).spam?).to be(false)
      expect(Ai::Base).not_to have_received(:new)
      expect(requests.size).to eq(1)
      expect(requests.first[:questions].keys)
        .to include(:advertisement, :malicious, :gibberish, :link_vehicle, :off_topic, :good_faith)
      expect(requests.first[:state][:article]).to include(title: article.title)
      expect(requests.first[:state][:community][:description]).to eq("A community for developers.")
    end

    it "flags clearly malicious articles" do
      stub_jev(malicious: 0.95)

      expect(described_class.new(article).spam?).to be(true)
    end

    it "flags clear advertisements that are not good-faith contributions" do
      stub_jev(advertisement: 0.9, good_faith: 0.2)

      expect(described_class.new(article).spam?).to be(true)
    end

    it "does not flag promotional content that is still a good-faith contribution" do
      stub_jev(advertisement: 0.9, good_faith: 0.8)

      expect(described_class.new(article).spam?).to be(false)
    end

    it "flags off-topic promotion but not off-topic content alone" do
      stub_jev(off_topic: 0.95, advertisement: 0.1, good_faith: 0.9)
      expect(described_class.new(article).spam?).to be(false)

      stub_jev(off_topic: 0.95, advertisement: 0.6, good_faith: 0.9)
      expect(described_class.new(article).spam?).to be(true)
    end

    it "does not flag borderline signals" do
      stub_jev(advertisement: 0.7, link_vehicle: 0.7, gibberish: 0.7, good_faith: 0.3)

      expect(described_class.new(article).spam?).to be(false)
    end

    it "asks about tag rules only when tags carry moderation instructions" do
      requests = stub_jev
      described_class.new(article).spam?
      expect(requests.last[:questions]).not_to have_key(:violates_tag_rules)

      article.tags << create(:tag, name: "jevtag", moderation_instructions: "No recruiting posts.")
      described_class.new(article).spam?
      expect(requests.last[:questions]).to have_key(:violates_tag_rules)
      expect(requests.last[:state][:community][:tag_moderation_instructions])
        .to eq([{ tag: "jevtag", instructions: "No recruiting posts." }])
    end

    it "returns false when TypeSafe fails" do
      client = instance_double(Ai::TypeSafe::Client)
      allow(Ai::TypeSafe::Client).to receive(:new).and_return(client)
      allow(client).to receive(:evaluate).and_raise(Ai::TypeSafe::Client::Error, "overloaded")

      expect(described_class.new(article).spam?).to be(false)
    end
  end
end
