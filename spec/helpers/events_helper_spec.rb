require "rails_helper"

RSpec.describe EventsHelper do
  describe "#calendar_range_header" do
    it "shows 'Today' for today's single day" do
      today = Time.zone.today
      expect(helper.calendar_range_header(today, today)).to eq("Today")
    end

    it "shows a weekday label for another single day" do
      day = Date.new(2026, 3, 10)
      expect(helper.calendar_range_header(day, day)).to eq("Tue, Mar 10")
    end

    it "collapses a same-month range" do
      expect(helper.calendar_range_header(Date.new(2026, 3, 15), Date.new(2026, 3, 17)))
        .to eq("Mar 15 – 17")
    end

    it "spells out a cross-month range" do
      expect(helper.calendar_range_header(Date.new(2026, 3, 30), Date.new(2026, 4, 2)))
        .to eq("Mar 30 – Apr 2")
    end
  end

  describe "#event_datetime_range" do
    it "shows start and end time for a same-day event" do
      event = build_stubbed(:event,
                            start_time: Time.zone.local(2026, 3, 10, 9, 0),
                            end_time: Time.zone.local(2026, 3, 10, 11, 0))
      expect(helper.event_datetime_range(event)).to eq("10 Mar 09:00 – 11:00")
    end

    it "shows both dates for a multi-day event" do
      event = build_stubbed(:event,
                            start_time: Time.zone.local(2026, 3, 10, 9, 0),
                            end_time: Time.zone.local(2026, 3, 18, 17, 0))
      expect(helper.event_datetime_range(event)).to eq("10 Mar 09:00 – 18 Mar 17:00")
    end
  end

  describe "#event_type_accent_class" do
    it "maps the event type to an accent class" do
      expect(helper.event_type_accent_class(build_stubbed(:event, type_of: "takeover")))
        .to eq("calendar__accent--takeover")
      expect(helper.event_type_accent_class(build_stubbed(:event, type_of: "meetup")))
        .to eq("calendar__accent--meetup")
      expect(helper.event_type_accent_class(build_stubbed(:event, type_of: "conference")))
        .to eq("calendar__accent--conference")
    end

    it "falls back to other for unknown types" do
      event = build_stubbed(:event, type_of: "live_stream")
      allow(event).to receive(:type_of).and_return("mystery")
      expect(helper.event_type_accent_class(event)).to eq("calendar__accent--other")
    end
  end

  describe "#event_pill_class" do
    it "maps event format labels to pill classes" do
      expect(helper.event_pill_class(build_stubbed(:event, type_of: "meetup"))).to eq("event-pill--meetup")
      expect(helper.event_pill_class(build_stubbed(:event, type_of: "conference"))).to eq("event-pill--conference")
      expect(helper.event_pill_class(build_stubbed(:event, type_of: "other"))).to eq("event-pill--default")
    end
  end

  describe "#safe_event_url" do
    it "allows http, https, and relative paths while rejecting unsafe schemes" do
      expect(helper.safe_event_url("https://example.com/conf")).to eq("https://example.com/conf")
      expect(helper.safe_event_url("/events/foo/bar")).to eq("/events/foo/bar")
      expect(helper.safe_event_url("javascript:alert(1)")).to be_nil
      expect(helper.safe_event_url("//evil.example")).to be_nil
      expect(helper.safe_event_url("")).to be_nil
    end
  end

  describe "#sidebar_events_heading" do
    let(:now) { Time.zone.local(2026, 10, 14, 12, 0) }
    let(:live_challenge) do
      build_stubbed(:event, type_of: "challenge", start_time: now - 1.hour, end_time: now + 1.day)
    end
    let(:upcoming_challenge) do
      build_stubbed(:event, type_of: "challenge", start_time: now + 1.day, end_time: now + 3.days)
    end
    let(:live_stream) do
      build_stubbed(:event, type_of: "live_stream", start_time: now - 30.minutes, end_time: now + 1.hour)
    end
    let(:upcoming_stream) do
      build_stubbed(:event, type_of: "live_stream", start_time: now + 2.hours, end_time: now + 3.hours)
    end
    let(:upcoming_takeover) do
      build_stubbed(:event, type_of: "takeover", start_time: now + 1.day, end_time: now + 2.days)
    end
    let(:live_takeover) do
      build_stubbed(:event, type_of: "takeover", start_time: now - 1.hour, end_time: now + 2.hours)
    end
    let(:upcoming_meetup) do
      build_stubbed(:event, type_of: "meetup", start_time: now + 1.day, end_time: now + 2.days)
    end
    let(:live_meetup) do
      build_stubbed(:event, type_of: "meetup", start_time: now - 1.hour, end_time: now + 2.hours)
    end
    let(:upcoming_conference) do
      build_stubbed(:event, type_of: "conference", start_time: now + 1.day, end_time: now + 2.days)
    end
    let(:live_conference) do
      build_stubbed(:event, type_of: "conference", start_time: now - 1.hour, end_time: now + 2.hours)
    end
    let(:upcoming_other) { build_stubbed(:event, type_of: "other", start_time: now + 1.day, end_time: now + 2.days) }

    it "returns 'Upcoming Challenges' when all events are upcoming challenges" do
      expect(helper.sidebar_events_heading([upcoming_challenge], now: now)).to eq("Upcoming Challenges")
    end

    it "returns 'Live Challenges' when all events are live challenges" do
      expect(helper.sidebar_events_heading([live_challenge], now: now)).to eq("Live Challenges")
    end

    it "returns 'Live and Upcoming Challenges' when challenges include both live and upcoming" do
      heading = helper.sidebar_events_heading([live_challenge, upcoming_challenge], now: now)
      expect(heading).to eq("Live and Upcoming Challenges")
    end

    it "returns 'Upcoming Livestreams' when all events are upcoming live streams" do
      expect(helper.sidebar_events_heading([upcoming_stream], now: now)).to eq("Upcoming Livestreams")
    end

    it "returns 'Live Livestreams' when all events are live streams currently live" do
      expect(helper.sidebar_events_heading([live_stream], now: now)).to eq("Live Livestreams")
    end

    it "returns 'Live and Upcoming Livestreams' when live streams include both live and upcoming" do
      heading = helper.sidebar_events_heading([live_stream, upcoming_stream], now: now)
      expect(heading).to eq("Live and Upcoming Livestreams")
    end

    it "returns 'Upcoming Takeovers' when all events are upcoming takeovers" do
      expect(helper.sidebar_events_heading([upcoming_takeover], now: now)).to eq("Upcoming Takeovers")
    end

    it "returns 'Live Takeovers' when all events are live takeovers" do
      expect(helper.sidebar_events_heading([live_takeover], now: now)).to eq("Live Takeovers")
    end

    it "returns 'Live and Upcoming Takeovers' when takeovers include both live and upcoming" do
      heading = helper.sidebar_events_heading([live_takeover, upcoming_takeover], now: now)
      expect(heading).to eq("Live and Upcoming Takeovers")
    end

    it "returns meetup and conference headings" do
      expect(helper.sidebar_events_heading([upcoming_meetup], now: now)).to eq("Upcoming Meetups")
      expect(helper.sidebar_events_heading([live_meetup], now: now)).to eq("Live Meetups")
      expect(helper.sidebar_events_heading([live_meetup, upcoming_meetup], now: now))
        .to eq("Live and Upcoming Meetups")
      expect(helper.sidebar_events_heading([upcoming_conference], now: now)).to eq("Upcoming Conferences")
      expect(helper.sidebar_events_heading([live_conference], now: now)).to eq("Live Conferences")
      expect(helper.sidebar_events_heading([live_conference, upcoming_conference], now: now))
        .to eq("Live and Upcoming Conferences")
    end

    it "returns 'Live and Upcoming Events' when mixed types include both live and upcoming" do
      heading = helper.sidebar_events_heading([live_challenge, upcoming_stream], now: now)
      expect(heading).to eq("Live and Upcoming Events")
    end

    it "returns 'Live Events' when mixed types are all live" do
      expect(helper.sidebar_events_heading([live_challenge, live_stream], now: now)).to eq("Live Events")
    end

    it "returns 'Upcoming Events' when mixed types are all upcoming or type is other" do
      expect(helper.sidebar_events_heading([upcoming_challenge, upcoming_stream], now: now)).to eq("Upcoming Events")
      expect(helper.sidebar_events_heading([upcoming_other], now: now)).to eq("Upcoming Events")
    end
  end

  describe "#sidebar_event_type_label" do
    it "returns human-readable labels for each event type" do
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "challenge"))).to eq("Challenge")
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "live_stream"))).to eq("Live Stream")
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "takeover"))).to eq("Takeover")
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "meetup"))).to eq("Meetup")
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "conference"))).to eq("Conference")
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "other"))).to eq("Event")
    end
  end

  describe "#event_time_slot_label" do
    it "shows distinct zone abbreviations when an event spans a DST transition" do
      zone = ActiveSupport::TimeZone["America/New_York"]
      event = build_stubbed(
        :event,
        start_time: zone.local(2026, 11, 1, 0, 30),
        end_time: zone.local(2026, 11, 1, 2, 30),
        data: { "time_zone" => "America/New_York" },
      )

      expect(helper.event_time_slot_label(event)).to eq("12:30 AM EDT – 2:30 AM EST")
    end

    it "shows a single trailing zone abbreviation when start and end share the same zone" do
      zone = ActiveSupport::TimeZone["America/New_York"]
      event = build_stubbed(
        :event,
        start_time: zone.local(2026, 11, 10, 10, 0),
        end_time: zone.local(2026, 11, 10, 11, 30),
        data: { "time_zone" => "America/New_York" },
      )

      expect(helper.event_time_slot_label(event)).to eq("10:00 AM – 11:30 AM EST")
    end
  end

  describe "#event_embed_stream_url" do
    it "only injects autoplay params for exact allowed streaming domains" do
      yt = build_stubbed(:event, primary_stream_url: "https://www.youtube.com/embed/abcdefghijk")
      spoof = build_stubbed(:event, primary_stream_url: "https://evil-youtube.com/embed/abcdefghijk")

      expect(helper.event_embed_stream_url(yt, autoplay: true, muted: true)).to include("autoplay=1", "mute=1")
      expect(helper.event_embed_stream_url(spoof, autoplay: true, muted: true)).to eq(
        "https://evil-youtube.com/embed/abcdefghijk",
      )
    end
  end

  describe "#event_banner_image_url" do
    it "routes external banner_image_url through optimized_image_url without random fallback" do
      event = build_stubbed(:event, data: { "banner_image_url" => "https://images.unsplash.com/photo-123" })
      allow(helper).to receive(:optimized_image_url)
        .with("https://images.unsplash.com/photo-123", width: 1200, random_fallback: false)
        .and_return("https://media.dev.to/cdn-cgi/image/width=1200/https://images.unsplash.com/photo-123")

      expect(helper.event_banner_image_url(event, width: 1200)).to eq(
        "https://media.dev.to/cdn-cgi/image/width=1200/https://images.unsplash.com/photo-123",
      )
    end

    it "returns nil for unsafe banner URLs" do
      event = build_stubbed(:event, data: { "banner_image_url" => "javascript:alert(1)" })

      expect(helper.event_banner_image_url(event)).to be_nil
    end

    it "keeps cover_image distinct from banner_image unless fallback_to_cover is true" do
      image = fixture_file_upload(Rails.root.join("spec/fixtures/files/800x600.png"), "image/png")
      event = create(:event, cover_image: image)

      expect(helper.event_banner_image_url(event)).to be_nil
      expect(helper.event_banner_image_url(event, fallback_to_cover: true)).to be_present
    end

    it "prefers uploaded banner_image over data banner_image_url and cover_image" do
      event = create(
        :event,
        cover_image: fixture_file_upload(Rails.root.join("spec/fixtures/files/800x600.png"), "image/png"),
        banner_image: fixture_file_upload(Rails.root.join("spec/fixtures/files/800x600.png"), "image/png"),
        data: { "banner_image_url" => "https://images.unsplash.com/photo-fallback" },
      )

      expect(helper.event_banner_image_url(event)).to include("banner_image")
      expect(helper.event_card_image_url(event)).to include("cover_image")
    end
  end

  describe "#event_card_image_url" do
    it "falls back to banner_image_url when no cover_image is uploaded" do
      event = build_stubbed(:event, data: { "banner_image_url" => "https://images.unsplash.com/photo-wide" })
      allow(helper).to receive(:optimized_image_url)
        .with("https://images.unsplash.com/photo-wide", width: 640, random_fallback: false)
        .and_return("https://media.dev.to/cdn-cgi/image/width=640/https://images.unsplash.com/photo-wide")

      expect(helper.event_card_image_url(event, width: 640)).to eq(
        "https://media.dev.to/cdn-cgi/image/width=640/https://images.unsplash.com/photo-wide",
      )
    end
  end

  describe "#event_host_path" do
    it "returns organization.path when organization is present and user.path otherwise" do
      org = build_stubbed(:organization, slug: "devteam")
      user = build_stubbed(:user, username: "ben")

      expect(helper.event_host_path(build_stubbed(:event, organization: org, user: user))).to eq("/devteam")
      expect(helper.event_host_path(build_stubbed(:event, organization: nil, user: user))).to eq("/ben")
      expect(helper.event_host_path(build_stubbed(:event, organization: nil, user: nil))).to be_nil
    end
  end
end
