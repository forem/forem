require "rails_helper"

RSpec.describe Events::Billboards::LiveStream do
  let(:start_time) { Time.utc(2026, 4, 16, 18, 30, 0) } # 2:30 PM ET
  
  let(:event) do
    create(:event,
           title: "Live Coding Session",
           description: "Watch us code live.",
           event_name_slug: "live-code",
           event_variation_slug: "04-16-2026",
           primary_stream_url: "https://www.youtube.com/embed/q6HJWch0bdM?autoplay=1",
           start_time: start_time)
  end

  subject(:service) { described_class.new(event) }

  describe "#feed_html" do
    it "generates the HTML with correct timezone hours infused in the initial javascript" do
      html = service.feed_html
      
      expect(html).to include("Live Coding Session")
      expect(html).to include("Watch us code live.")
      expect(html).to include("href=\"/events/live-code/04-16-2026\"")
      expect(html).to include("id=\"overlay-feed-#{event.id}\"")
      expect(html).to include("id=\"player-container-feed-#{event.id}\"")
      
      # The script passes the absolute start timestamp
      expect(html).to include("const TARGET_TIME = new Date(#{event.start_time.iso8601.to_json}).getTime();")
      expect(html).to include("const IFRAME_SRC = #{event.primary_stream_url.to_json};")
    end
  end

  describe "#post_html" do
    it "generates the HTML with correct timezone hours infused in the initial javascript" do
      html = service.post_html
      
      expect(html).to include("Live Coding Session")
      expect(html).to include("Watch us code live.")
      expect(html).to include("href=\"/events/live-code/04-16-2026\"")
      expect(html).to include("id=\"overlay-post-#{event.id}\"")
      expect(html).to include("id=\"player-container-post-#{event.id}\"")
      
      expect(html).to include("const TARGET_TIME = new Date(#{event.start_time.iso8601.to_json}).getTime();")
      expect(html).to include("const IFRAME_SRC = #{event.primary_stream_url.to_json};")
    end
  end
end
