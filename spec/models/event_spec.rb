require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    # Validations tests have been moved into their dedicated block extending boundaries.
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:organization).optional }
    it { is_expected.to belong_to(:page).optional }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:type_of).with_values(
        live_stream: 0,
        takeover: 1,
        other: 2,
        challenge: 3
      )
    end
    it do
      is_expected.to define_enum_for(:broadcast_config).with_values(
        no_broadcast: 0,
        tagged_broadcast: 1,
        global_broadcast: 2
      )
    end
  end

  describe "validations" do
    let(:subject) { build(:event, event_name_slug: "test-event", event_variation_slug: "v1") }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
    it { is_expected.to validate_presence_of(:event_name_slug) }
    it { is_expected.to validate_presence_of(:event_variation_slug) }
    
    it "requires uniqueness of event_variation_slug scoped to event_name_slug" do
      create(:event, event_name_slug: "test-event", event_variation_slug: "v1")
      duplicate = build(:event, event_name_slug: "test-event", event_variation_slug: "v1")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:event_variation_slug]).to include("has already been taken")

      different = build(:event, event_name_slug: "test-event-2", event_variation_slug: "v1")
      expect(different).to be_valid
    end

    describe "slug formats" do
      it "allows valid slugs" do
        expect(build(:event, event_name_slug: "valid-1", event_variation_slug: "valid-2")).to be_valid
      end

      it "rejects invalid slugs" do
        bad_event = build(:event, event_name_slug: "Invalid_1", event_variation_slug: "V 2!")
        expect(bad_event).not_to be_valid
        expect(bad_event.errors[:event_name_slug]).to be_present
        expect(bad_event.errors[:event_variation_slug]).to be_present
      end
    end

    describe "primary_stream_url format" do
      it "allows valid youtube, twitch, or streamyard https URLs" do
        expect(build(:event, primary_stream_url: "https://www.youtube.com/watch?v=1234567890a")).to be_valid
        expect(build(:event, primary_stream_url: "https://twitch.tv/ThePracticalDev")).to be_valid
        expect(build(:event, primary_stream_url: "https://streamyard.com/watch/12345")).to be_valid
      end

      it "rejects non-https, XSS, or unknown URLs" do
        expect(build(:event, primary_stream_url: "http://twitch.tv/test")).not_to be_valid
        expect(build(:event, primary_stream_url: "https://example.com")).not_to be_valid
        expect(build(:event, primary_stream_url: "javascript:alert(1)")).not_to be_valid
      end
    end

    describe "page delegation validation" do
      it "requires page when delegate_to_page is true" do
        event = build(:event, delegate_to_page: true, page: nil)
        expect(event).not_to be_valid
        expect(event.errors[:page]).to include("can't be blank")

        page = build(:page)
        event.page = page
        expect(event).to be_valid
      end

      it "does not require page when delegate_to_page is false" do
        event = build(:event, delegate_to_page: false, page: nil)
        expect(event).to be_valid
      end
    end
  end

  describe "#format_stream_urls" do
    it "automatically binds chat_url and embedded URLs for Twitch" do
      event = create(:event, primary_stream_url: "https://twitch.tv/ThePracticalDev")
      expect(event.primary_stream_url).to include("player.twitch.tv/?channel=ThePracticalDev")
      expect(event.data["chat_url"]).to include("twitch.tv/embed/ThePracticalDev/chat")
    end

    it "automatically binds chat_url and embedded URLs for YouTube" do
      event = create(:event, primary_stream_url: "https://youtu.be/abcdefghijk")
      expect(event.primary_stream_url).to include("youtube.com/embed/abcdefghijk?autoplay=1")
      expect(event.data["chat_url"]).to include("youtube.com/live_chat?v=abcdefghijk")
    end

    it "automatically embeds URLs for Streamyard and does not set chat_url" do
      event1 = create(:event, primary_stream_url: "https://streamyard.com/watch/12345")
      expect(event1.primary_stream_url).to eq("https://streamyard.com/e/12345")
      expect(event1.data["chat_url"]).to be_nil

      event2 = create(:event, primary_stream_url: "https://streamyard.com/e/12345")
      expect(event2.primary_stream_url).to eq("https://streamyard.com/e/12345")
      
      event3 = create(:event, primary_stream_url: "https://streamyard.com/12345")
      expect(event3.primary_stream_url).to eq("https://streamyard.com/e/12345")
    end
  end

  describe "#ensure_broadcast_billboards_and_workers" do
    it "does not generate billboards for no_broadcast events" do
      event = create(:event, broadcast_config: "no_broadcast")
      expect(event.billboards).to be_empty
    end

    it "generates fully formulated HTML billboards containing dynamic parameters for a takeover" do
      user = create(:user)
      event = create(:event, 
                     broadcast_config: "global_broadcast", 
                     type_of: "takeover",
                     title: "Test HTML Event", 
                     description: "A very exciting summary",
                     event_name_slug: "test-html-event", 
                     event_variation_slug: "v1",
                     data: { "image_url" => "https://dummyimage.com/img.jpg" },
                     user: user)

      # 2 billboards (feed_first, post_fixed_bottom)
      expect(event.billboards.count).to eq(2)
      
      feed_bb = event.billboards.find_by(placement_area: "feed_first")
      post_bb = event.billboards.find_by(placement_area: "post_fixed_bottom")

      expect(feed_bb.published).to be(true)
      expect(feed_bb.approved).to be(false) # Needs worker to approve
      
      expect(feed_bb.render_mode).to eq("raw")
      expect(feed_bb.template).to eq("authorship_box")
      expect(post_bb.template).to eq("authorship_box")
      expect(feed_bb.custom_display_label).to eq("#{Settings::Community.community_name} Takeovers")
      
      expect(feed_bb.name).to start_with("takeover_")
      expect(feed_bb.dismissal_sku).to start_with("takeover_")
      expect(feed_bb.name).to include("_feed")
      
      expect(post_bb.render_mode).to eq("raw")
      expect(post_bb.template).to eq("authorship_box")
      expect(post_bb.dismissal_sku).to eq(feed_bb.dismissal_sku)
      expect(post_bb.name).to include("_post")
      expect(post_bb.name).to_not eq(feed_bb.name)
      
      # Assert the HTML was injected cleanly inside body_markdown using user fallback
      expect(feed_bb.body_markdown).to include("id=\"event-takeover-image-feed\"")
      expect(feed_bb.body_markdown).to include("Tune in to the full event")
      expect(feed_bb.body_markdown).to include("Test HTML Event")
      expect(feed_bb.body_markdown).to include("A very exciting summary")
      expect(feed_bb.body_markdown).to include("/events/test-html-event/v1")
      expect(feed_bb.body_markdown).to include("https://dummyimage.com/img.jpg")

      expect(post_bb.body_markdown).to include("id=\"event-takeover-image\"")
    end

    it "generates persistent on-post billboard with minimized HTML for a live_stream event" do
      user = create(:user)
      event = create(:event, 
                     broadcast_config: "global_broadcast", 
                     type_of: "live_stream",
                     title: "Test Live Stream Event", 
                     description: "A live broadcast summary",
                     event_name_slug: "test-live-stream", 
                     event_variation_slug: "v1",
                     user: user)

      expect(event.billboards.count).to eq(2)
      
      feed_bb = event.billboards.find_by(placement_area: "feed_first")
      post_bb = event.billboards.find_by(placement_area: "post_fixed_bottom")

      expect(feed_bb.custom_display_label).to eq("#{Settings::Community.community_name} Live Events")
      
      expect(post_bb.special_behavior).to eq("persistent")
      expect(post_bb.minimized_body_markdown).to include("live-stream-minimized")
      expect(post_bb.minimized_body_markdown).to include("Test Live Stream Event")
      expect(post_bb.minimized_body_markdown).to include("A live broadcast summary")
      expect(post_bb.minimized_body_markdown).to include("/events/test-live-stream/v1")
      expect(post_bb.minimized_body_markdown).to include("media-wrapper-minimized")
      expect(post_bb.minimized_body_markdown).to include("player-container-minimized")
      expect(post_bb.minimized_processed_html).to include("live-stream-minimized")
    end
  end

  describe "Callbacks" do
    it "registers #bust_upcoming_events_cache as an after_commit callback" do
      callback_names = Event._commit_callbacks.select { |cb| cb.kind == :after }.map(&:filter)
      expect(callback_names).to include(:bust_upcoming_events_cache)
    end
  end

  describe "#bust_upcoming_events_cache" do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    after do
      Rails.cache.clear
    end

    it "deletes the upcoming_elevated_events cache key" do
      Rails.cache.write("upcoming_elevated_events", ["cached_data"])
      expect(Rails.cache.read("upcoming_elevated_events")).to eq(["cached_data"])

      build(:event).send(:bust_upcoming_events_cache)

      expect(Rails.cache.read("upcoming_elevated_events")).to be_nil
    end
  end
end

