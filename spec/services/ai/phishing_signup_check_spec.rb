require "rails_helper"

RSpec.describe Ai::PhishingSignupCheck, type: :service do
  let(:user) do
    create(:user, name: "𝘿𝙚𝙫 𝙎𝙪𝙥𝙥𝙤𝙧𝙩 𝙏𝙚𝙖𝙢", username: "devteamsupp").tap do |u|
      u.profile.update!(summary: "Official account of the Dev support team")
    end
  end
  let(:phishing_article) do
    create(
      :published_article,
      user: user,
      title: "Mаndаtоry usеr vеrificаtiоn",
      body_markdown: "𝙈𝙖𝙣𝙙𝙖𝙩𝙤𝙧𝙮 𝙪𝙨𝙚𝙧 𝙫𝙚𝙧𝙞𝙛𝙞𝙘𝙖𝙩𝙞𝙤𝙣\n" \
                     "Dеar User, Due to an increase in bot activity on the platform, we require vеriflcation of " \
                     "your account. Please log in via the link below:\ntr.ee/dev-to\n" \
                     "Vеriflcation deadline — 12 hours. Failure to vеrify will result in restricted access. " \
                     "Sincerely, Dev Suppоrt.",
    )
  end
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::Community).to receive_messages(
      community_name: "DEV Community",
      community_description: "A constructive and inclusive social network for software developers.",
    )
  end

  describe ".normalize_obfuscated_text" do
    it "normalizes Mathematical Sans-Serif Bold Italic and Cyrillic homoglyphs into plain ASCII" do
      expect(described_class.normalize_obfuscated_text("𝙈𝙖𝙣𝙙𝙖𝙩𝙤𝙧𝙮 𝙪𝙨𝙚𝙧 𝙫𝙚𝙧𝙞𝙛𝙞𝙘𝙖𝙩𝙞𝙤𝙣"))
        .to eq("Mandatory user verification")
      expect(described_class.normalize_obfuscated_text("𝘿𝙚𝙫 𝙎𝙪𝙥𝙥𝙤𝙧𝙩 𝙏𝙚𝙖𝙢"))
        .to eq("Dev Support Team")
      expect(described_class.normalize_obfuscated_text("Dеar User, Dev Suppоrt, Suрроrt Воt"))
        .to eq("Dear User, Dev Support, Support Bot")
    end
  end

  describe ".unicode_obfuscated?" do
    it "detects mathematical fonts and mixed-script Cyrillic/Latin words" do
      expect(described_class.unicode_obfuscated?("𝘿𝙚𝙫 𝙎𝙪𝙥𝙥𝙤𝙧𝙩 𝙏𝙚𝙖𝙢")).to be(true)
      expect(described_class.unicode_obfuscated?("Dеar User")).to be(true)
      expect(described_class.unicode_obfuscated?("Normal Developer Text")).to be(false)
    end
  end

  describe "#spam? (Gemini)" do
    it "returns true when Gemini responds YES" do
      allow(ai_client).to receive(:call).and_return("YES")

      expect(described_class.new(phishing_article).spam?).to be(true)
    end

    it "returns false when Gemini responds NO" do
      allow(ai_client).to receive(:call).and_return("NO")

      expect(described_class.new(phishing_article).spam?).to be(false)
    end

    it "includes both original and normalized text and obfuscation flags in the Gemini prompt" do
      allow(ai_client).to receive(:call).and_return("YES")

      checker = described_class.new(phishing_article)
      prompt = checker.__send__(:build_prompt)

      expect(prompt).to include("Normalized Name: Dev Support Team")
      expect(prompt).to include("Normalized Title: Mandatory user verification")
      expect(prompt).to include("Dear User, Due to an increase in bot activity")
      expect(prompt).to include("Unicode/Homoglyph Obfuscation in Profile: YES")
      expect(prompt).to include("Unicode/Homoglyph Obfuscation in Content: YES")
    end

    it "re-checks a comment in isolation if the parent post triggers ProhibitedContentError" do
      comment = create(:comment, user: user, commentable: phishing_article, body_markdown: "Verify now")
      call_count = 0
      allow(ai_client).to receive(:call) do
        call_count += 1
        raise Ai::Base::ProhibitedContentError, "blocked" if call_count == 1

        "YES"
      end

      expect(described_class.new(comment).spam?).to be(true)
      expect(call_count).to eq(2)
    end
  end

  describe "#spam? with Jev selected" do
    before { enable_jev_for(:phishing_signup_check) }

    it "evaluates narrow TypeSafe questions with normalized author and content state" do
      requests = stub_jev

      expect(described_class.new(phishing_article).spam?).to be(false)
      expect(Ai::Base).not_to have_received(:new)
      expect(requests.size).to eq(1)
      expect(requests.first[:questions].keys).to contain_exactly(
        :platform_impersonation,
        :phishing_or_verification_lure,
        :suspicious_signup_solicitation,
        :good_faith_contribution,
      )
      expect(requests.first[:state][:author]).to include(
        normalized_name: "Dev Support Team",
        unicode_obfuscation_detected: true,
      )
      expect(requests.first[:state][:content]).to include(
        normalized_title: "Mandatory user verification",
        unicode_obfuscation_detected: true,
      )
    end

    it "flags clear platform impersonation" do
      stub_jev(platform_impersonation: 0.92)

      expect(described_class.new(phishing_article).spam?).to be(true)
    end

    it "flags clear phishing or verification lures" do
      stub_jev(phishing_or_verification_lure: 0.9)

      expect(described_class.new(phishing_article).spam?).to be(true)
    end

    it "flags combined platform impersonation and signup/verification solicitation" do
      stub_jev(platform_impersonation: 0.65, suspicious_signup_solicitation: 0.7)

      expect(described_class.new(phishing_article).spam?).to be(true)
    end

    it "flags suspicious signup solicitation when not a good-faith contribution" do
      stub_jev(suspicious_signup_solicitation: 0.9, good_faith_contribution: 0.2)

      expect(described_class.new(phishing_article).spam?).to be(true)
    end

    it "does not flag good-faith project launches" do
      stub_jev(suspicious_signup_solicitation: 0.9, good_faith_contribution: 0.85)

      expect(described_class.new(phishing_article).spam?).to be(false)
    end
  end
end
