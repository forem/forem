require "rails_helper"

RSpec.describe Ai::ProfileModerationLabeler, type: :service do
  let(:user) { create(:user) }

  before do
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::Community).to receive(:community_description).and_return("A community for developers.")
  end

  describe "#label with Gemini (default)" do
    it "parses the label from the response" do
      ai_client = instance_double(Ai::Base, call: "clear_and_obvious_spam")

      expect(described_class.new(user, ai_client: ai_client).label).to eq("clear_and_obvious_spam")
    end

    it "does not false-match a negated clear_and_obvious_spam mention before the chosen label" do
      response = "This profile is not clear_and_obvious_spam; the appropriate label is okay_and_on_topic."
      ai_client = instance_double(Ai::Base, call: response)

      expect(described_class.new(user, ai_client: ai_client).label).to eq("okay_and_on_topic")
    end

    it "returns no_moderation_label when the only mentioned label is negated" do
      response = "This is not clear_and_obvious_spam."
      ai_client = instance_double(Ai::Base, call: response)

      expect(described_class.new(user, ai_client: ai_client).label).to eq("no_moderation_label")
    end

    it "includes non-blank custom profile fields from onboarding in the prompt" do
      user.profile.update_columns(
        data: {
          "skills_languages" => "TypeScript, Rust, PostgreSQL",
          "currently_learning" => "Distributed systems",
          "social_image" => "https://example.com/ignored.png"
        },
      )
      captured_prompt = nil
      ai_client = instance_double(Ai::Base)
      allow(ai_client).to receive(:call) do |prompt|
        captured_prompt = prompt
        "no_moderation_label"
      end

      expect(described_class.new(user, ai_client: ai_client).label).to eq("no_moderation_label")
      expect(captured_prompt).to include("Skills languages: TypeScript, Rust, PostgreSQL")
      expect(captured_prompt).to include("Currently learning: Distributed systems")
      expect(captured_prompt).not_to include("ignored.png")
    end
  end

  describe "#label with Jev selected" do
    before { enable_jev_for(:profile_moderation) }

    it "returns no label when nothing is flagged" do
      requests = stub_jev

      expect(described_class.new(user).label).to eq("no_moderation_label")
      expect(requests.first[:state][:profile]).to include(username: user.username)
      expect(requests.first[:state][:profile]).not_to have_key(:fields)
      expect(requests.first[:questions]).not_to have_key(:spam_articles)
    end

    it "includes non-blank custom profile fields in the Jev profile state" do
      user.profile.update_columns(
        data: {
          "skills_languages" => "Go, React",
          "work" => "Backend Engineer",
          "social_image" => "https://example.com/social.png"
        },
      )
      requests = stub_jev

      expect(described_class.new(user).label).to eq("no_moderation_label")
      expect(requests.first[:state][:profile][:fields]).to eq(
        "skills_languages" => "Go, React",
        "work" => "Backend Engineer",
      )
    end

    it "labels clear SEO spam" do
      stub_jev(keyword_stuffed_identity: 0.92)

      expect(described_class.new(user).label).to eq("clear_and_obvious_spam")
    end

    it "gives safety labels precedence over spam" do
      stub_jev(harmful: 0.9, promotional_profile: 0.95)

      expect(described_class.new(user).label).to eq("clear_and_obvious_harmful")
    end

    it "returns likely labels for the uncertain band, which Spam::Handler does not act on" do
      stub_jev(inciting: 0.7)

      expect(described_class.new(user).label).to eq("likely_inciting")
    end

    it "checks recent articles when the user has published" do
      create(:article, user: user, published: true)
      requests = stub_jev(spam_articles: 0.9)

      expect(described_class.new(user).label).to eq("clear_and_obvious_spam")
      expect(requests.first[:state][:recent_articles].size).to eq(1)
    end

    it "uses an injected Gemini client instead of Jev" do
      ai_client = instance_double(Ai::Base, call: "no_moderation_label")
      allow(Ai::TypeSafe::Client).to receive(:new)

      described_class.new(user, ai_client: ai_client).label

      expect(Ai::TypeSafe::Client).not_to have_received(:new)
    end
  end
end
