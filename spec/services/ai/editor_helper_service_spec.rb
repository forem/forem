require "rails_helper"

RSpec.describe Ai::EditorHelperService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe "#prompt" do
    before do
      # Disable caching so we can consistently test the final prompt string rendering dynamically
      allow(Rails.cache).to receive(:fetch).and_yield
      
      # Mock the dependent views natively wrapped by ActionView
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(/_editor_guide_text.en.html.erb/).and_return("Clean editor guide mocked.")
      allow(File).to receive(:read).with(/_supported_url_embeds_list.en.html.erb/).and_return("Clean url embed mocked.")
      allow(File).to receive(:read).with(/_supported_nonurl_embeds_list.en.html.erb/).and_return("Clean block embed mocked.")
    end

    it "embeds the hardcoded platform mechanics natively" do
      prompt = service.send(:prompt)

      expect(prompt).to include("insightful technical editor assistant for the #{Settings::Community.community_name} community")
      expect(prompt).to include("Platform Mechanics Overview:")
      expect(prompt).to include("Tags are the primary organizational mechanism on the platform.")
      expect(prompt).to include("Catchy, plain-language titles historically perform better.")
      expect(prompt).to include("Forem utilizes a heavily personalized algorithm")
    end

    it "enforces constraints against unsolicited advice in the guidelines" do
      prompt = service.send(:prompt)
      
      expect(prompt).to include("NEVER give unsolicited advice on what subjects to write about or how to structure the story itself UNLESS the user explicitly asks")
    end

    describe "content advisement specs" do
      context "when neither spec has values" do
        it "does not render the advisement context block" do
          allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
          allow(Settings::RateLimit).to receive(:expanded_content_advisement_spec).and_return(nil)

          prompt = service.send(:prompt)
          expect(prompt).not_to include("The platform explicitly specifies the following about ideal content")
        end
      end

      context "when specs are configured" do
        it "embeds the configured specs actively inside the prompt pipeline" do
          allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return("We are a Ruby specific subset.")
          allow(Settings::RateLimit).to receive(:expanded_content_advisement_spec).and_return("Focus on deep technical blocks.")

          prompt = service.send(:prompt)
          
          expect(prompt).to include("The platform explicitly specifies the following about ideal content:")
          expect(prompt).to include("We are a Ruby specific subset.")
          expect(prompt).to include("Focus on deep technical blocks.")
        end
      end
    end
  end
end
