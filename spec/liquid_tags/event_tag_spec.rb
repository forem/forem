require "rails_helper"

RSpec.describe EventTag, type: :liquid_tag do
  let(:event_start_time) { Time.zone.parse("2026-06-30 10:00:00") }
  let(:event) { create(:event, title: "Google Cloud Live June", event_name_slug: "google-cloud-live", event_variation_slug: "june-30-2026", description: "Awesome Cloud Event", start_time: event_start_time, end_time: event_start_time + 2.hours) }

  before do
    Liquid::Template.register_tag("event", described_class)
  end

  describe ".script" do
    it "returns the SCRIPT constant containing event card handler JS" do
      expect(described_class.script).to include("ltag__event")
      expect(described_class.script).to include("signup_status")
    end
  end

  context "when rendering" do
    let!(:existing_event) { event }

    it "renders correctly using event ID" do
      liquid_tag = Liquid::Template.parse("{% event #{existing_event.id} %}").render
      expect(liquid_tag).to include("Google Cloud Live June")
      expect(liquid_tag).to include("Awesome Cloud Event")
      expect(liquid_tag).to include("June 30, 2026")
      expect(liquid_tag).to include(CGI.escapeHTML("I'm Interested"))
    end

    it "renders correctly using event slugs path" do
      liquid_tag = Liquid::Template.parse("{% event google-cloud-live/june-30-2026 %}").render
      expect(liquid_tag).to include("Google Cloud Live June")
      expect(liquid_tag).to include("Awesome Cloud Event")
    end

    it "renders correctly inside universal embed tag" do
      # Note: Universal embed delegates to UnifiedEmbed::Registry
      url = "#{URL.url}/events/google-cloud-live/june-30-2026"
      liquid_tag = Liquid::Template.parse("{% embed #{url} %}").render
      expect(liquid_tag).to include("Google Cloud Live June")
      expect(liquid_tag).to include("Awesome Cloud Event")
    end

    it "raises StandardError when event cannot be found" do
      expect {
        Liquid::Template.parse("{% event 999999 %}").render
      }.to raise_error(StandardError, /Event not found/)

      expect {
        Liquid::Template.parse("{% event non-existent/event %}").render
      }.to raise_error(StandardError, /Event not found/)
    end

    it "renders correct challenge signup button text if type is challenge" do
      challenge_event = create(:event, type_of: :challenge, event_name_slug: "my-challenge", event_variation_slug: "july-2026")
      liquid_tag = Liquid::Template.parse("{% event #{challenge_event.id} %}").render
      expect(liquid_tag).to include("Sign Up")
      expect(liquid_tag).not_to include("I'm Interested")
    end
  end
end
