require "rails_helper"

RSpec.describe Events::Billboards::Takeover do
  let(:event) do
    create(:event,
           title: "Awesome Tech Conference",
           description: "The biggest tech conference of the year.",
           event_name_slug: "tech-conf",
           event_variation_slug: "2026",
           data: { "image_url" => "https://example.com/image.jpg" })
  end

  subject(:service) { described_class.new(event) }

  describe "#feed_html" do
    it "generates the expected HTML layout for the feed including title, description, and link" do
      html = service.feed_html
      expect(html).to include("Awesome Tech Conference")
      expect(html).to include("The biggest tech conference of the year.")
      expect(html).to include("src=\"https://example.com/image.jpg\"")
      expect(html).to include("href=\"/events/tech-conf/2026\"")
      expect(html).to include("id=\"event-takeover-image-feed\"")
    end
  end

  describe "#post_html" do
    it "generates the expected HTML layout for the post fixed position including title, description, and link" do
      html = service.post_html
      expect(html).to include("Awesome Tech Conference")
      expect(html).to include("The biggest tech conference of the year.")
      expect(html).to include("src=\"https://example.com/image.jpg\"")
      expect(html).to include("href=\"/events/tech-conf/2026\"")
      expect(html).to include("id=\"event-takeover-image\"")
    end
  end

  describe "fallback image logic" do
    let(:organization) { create(:organization, profile_image_url: "https://example.com/org.jpg") }

    it "falls back to the organization image if data image_url is blank" do
      event.data.delete("image_url")
      event.organization = organization
      
      html = service.post_html
      expect(html).to include("src=\"https://example.com/org.jpg\"")
    end
  end
end
