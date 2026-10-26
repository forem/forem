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
      event = build_stubbed(:event, type_of: "takeover")
      expect(helper.event_type_accent_class(event)).to eq("calendar__accent--takeover")
    end

    it "falls back to other for unknown types" do
      event = build_stubbed(:event, type_of: "live_stream")
      allow(event).to receive(:type_of).and_return("mystery")
      expect(helper.event_type_accent_class(event)).to eq("calendar__accent--other")
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
      expect(helper.sidebar_event_type_label(build_stubbed(:event, type_of: "other"))).to eq("Event")
    end
  end
end
