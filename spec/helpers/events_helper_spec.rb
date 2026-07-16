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
end
