require "rails_helper"

RSpec.describe "Calendar" do
  describe "GET /calendar" do
    let!(:this_month_event) do
      create(:event, title: "This Month Event", published: true,
                     start_time: Time.zone.today.beginning_of_month + 9.hours,
                     end_time: Time.zone.today.beginning_of_month + 11.hours)
    end
    let!(:draft_event) do
      create(:event, title: "Secret Draft", published: false,
                     start_time: Time.zone.today.beginning_of_month + 9.hours,
                     end_time: Time.zone.today.beginning_of_month + 11.hours)
    end

    it "renders successfully and lists published events in the current month" do
      get calendar_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(this_month_event.title)
      expect(response.body).not_to include(draft_event.title)
    end

    context "with a start/end range" do
      let!(:in_range) do
        create(:event, title: "In Range", published: true,
                       start_time: Date.new(2026, 3, 10).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 3, 10).in_time_zone + 11.hours)
      end
      let!(:out_of_range) do
        create(:event, title: "Out Of Range", published: true,
                       start_time: Date.new(2026, 5, 10).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 5, 10).in_time_zone + 11.hours)
      end

      it "lists only events within the range" do
        get calendar_path(start: "2026-03-01", end: "2026-03-31")

        expect(response.body).to include(in_range.title)
        expect(response.body).not_to include(out_of_range.title)
      end

      it "lists only that day's events for a single-day range" do
        other_march_day = create(:event, title: "Other March Day", published: true,
                                         start_time: Date.new(2026, 3, 20).in_time_zone + 9.hours,
                                         end_time: Date.new(2026, 3, 20).in_time_zone + 11.hours)
        get calendar_path(start: "2026-03-10", end: "2026-03-10")

        expect(response.body).to include(in_range.title)
        expect(response.body).not_to include(out_of_range.title)
        expect(response.body).not_to include(other_march_day.title)
      end
    end

    context "with a type_of filter" do
      let!(:stream) do
        create(:event, title: "Stream One", published: true, type_of: "live_stream",
                       start_time: Time.zone.today.beginning_of_month + 9.hours,
                       end_time: Time.zone.today.beginning_of_month + 11.hours)
      end
      let!(:takeover) do
        create(:event, :takeover, title: "Takeover One", published: true,
                                  start_time: Time.zone.today.beginning_of_month + 9.hours,
                                  end_time: Time.zone.today.beginning_of_month + 11.hours)
      end

      it "lists only events of the requested type" do
        get calendar_path(type_of: "takeover")

        expect(response.body).to include(takeover.title)
        expect(response.body).not_to include(stream.title)
      end
    end

    context "with invalid params" do
      let!(:current) do
        create(:event, title: "Current Month Event", published: true,
                       start_time: Time.zone.today.beginning_of_month + 9.hours,
                       end_time: Time.zone.today.beginning_of_month + 11.hours)
      end

      it "falls back to the current month and ignores a bad type" do
        get calendar_path(start: "not-a-date", end: "garbage", type_of: "bogus")

        expect(response).to have_http_status(:success)
        expect(response.body).to include(current.title)
      end
    end

    context "with calendar widget rendering" do
      it "shows the displayed month name and prev/next navigation links" do
        get calendar_path(start: "2026-03-01", end: "2026-03-31")

        expect(response.body).to include("March 2026")
        expect(response.body).to include("month=2026-02")
        expect(response.body).to include("month=2026-04")
      end

      it "pages the grid to another month without changing the selected range" do
        get calendar_path(start: "2026-03-10", end: "2026-03-12", month: "2026-04")

        # The grid shows the browsed month...
        expect(response.body).to include("April 2026")
        # ...while the selection (date inputs) and nav links keep the chosen range.
        expect(response.body).to include('value="2026-03-10"')
        expect(response.body).to include('value="2026-03-12"')
        expect(response.body).to include("start=2026-03-10")
        expect(response.body).to include("end=2026-03-12")
      end

      it "ignores a malformed month param and falls back to the range month" do
        get calendar_path(start: "2026-03-01", end: "2026-03-31", month: "not-a-month")

        expect(response).to have_http_status(:success)
        expect(response.body).to include("March 2026")
      end

      it "marks days that have events" do
        create(:event, title: "Dotted Day", published: true,
                       start_time: Date.new(2026, 3, 12).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 3, 12).in_time_zone + 11.hours)
        get calendar_path(start: "2026-03-01", end: "2026-03-31")

        expect(response.body).to include("calendar__day--has-event")
        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>12</)
      end

      it "does not mark days when no events fall in the month" do
        get calendar_path(start: "2025-01-01", end: "2025-01-31")

        expect(response.body).not_to include("calendar__day--has-event")
      end
    end

    context "with event row details" do
      let!(:row_event) do
        create(:event, title: "Detailed Event", published: true, type_of: "live_stream",
                       start_time: Time.zone.today.beginning_of_month + 9.hours,
                       end_time: Time.zone.today.beginning_of_month + 11.hours)
      end

      it "shows the type label" do
        get calendar_path

        expect(response.body).to include("Live Stream")
      end

      it "renders a view-event action linking to the event" do
        get calendar_path

        expect(response.body).to include("View event")
        expect(response.body).to include(event_path(row_event.event_name_slug, row_event.event_variation_slug))
      end

      it "does not show an attendee count" do
        create(:event_signup, event: row_event)
        get calendar_path

        expect(response.body).not_to include("attendee")
      end
    end

    context "when signed in and attending an event" do
      let(:user) { create(:user) }
      let!(:row_event) do
        create(:event, title: "Detailed Event", published: true, type_of: "live_stream",
                       start_time: Time.zone.today.beginning_of_month + 9.hours,
                       end_time: Time.zone.today.beginning_of_month + 11.hours)
      end

      before do
        create(:event_signup, event: row_event, user: user)
        login_as(user)
      end

      it "shows an attending badge" do
        get calendar_path

        expect(response.body).to include("Attending")
      end
    end

    context "when not signed in" do
      let!(:anon_event) do
        create(:event, title: "Anon Event", published: true, type_of: "live_stream",
                       start_time: Time.zone.today.beginning_of_month + 9.hours,
                       end_time: Time.zone.today.beginning_of_month + 11.hours)
      end

      it "does not show an attending badge" do
        get calendar_path

        expect(response.body).to include(anon_event.title)
        expect(response.body).not_to include("Attending")
      end
    end

    context "when signed in but not attending an event" do
      let(:user) { create(:user) }
      let!(:row_event) do
        create(:event, title: "Non-Attended Event", published: true, type_of: "live_stream",
                       start_time: Time.zone.today.beginning_of_month + 9.hours,
                       end_time: Time.zone.today.beginning_of_month + 11.hours)
      end

      before do
        login_as(user)
      end

      it "does not show an attending badge" do
        get calendar_path

        expect(response.body).to include(row_event.title)
        expect(response.body).not_to include("Attending")
      end
    end

    context "with more events than fit on one page" do
      before do
        month_start = Time.zone.today.beginning_of_month
        15.times do |i|
          create(:event, title: "Paged Event #{i}", published: true,
                         start_time: month_start + 9.hours + i.minutes,
                         end_time: month_start + 11.hours + i.minutes)
        end
      end

      it "shows only the first page and a next-page link" do
        get calendar_path
        expect(response.body).to include("Paged Event 0")
        expect(response.body).not_to include("Paged Event 12")
        expect(response.body).to include("page=2")
      end

      it "shows the remaining events on page two" do
        get calendar_path(page: 2)
        expect(response.body).to include("Paged Event 12")
        expect(response.body).not_to include("Paged Event 0")
      end
    end

    context "with the agenda range header and accent" do
      it "renders a range header and a type accent bar" do
        create(:event, title: "Headered", published: true, type_of: "live_stream",
                       start_time: Date.new(2026, 3, 10).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 3, 10).in_time_zone + 11.hours)
        get calendar_path(start: "2026-03-10", end: "2026-03-12")

        expect(response.body).to include("Mar 10 – 12")
        expect(response.body).to include("calendar__accent--live_stream")
      end
    end

    context "with the dot set spanning the visible month" do
      it "keeps event dots on other days when a single day is selected" do
        create(:event, title: "Day Five", published: true,
                       start_time: Date.new(2026, 3, 5).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 3, 5).in_time_zone + 11.hours)
        create(:event, title: "Day Twenty", published: true,
                       start_time: Date.new(2026, 3, 20).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 3, 20).in_time_zone + 11.hours)

        get calendar_path(start: "2026-03-12", end: "2026-03-12")

        # Dots come from the whole month, not just the selected day.
        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>5</)
        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>20</)
      end
    end

    context "with a multi-day event" do
      let!(:multi_day) do
        create(:event, title: "Nine Day Conference", published: true,
                       start_time: Date.new(2026, 3, 10).in_time_zone + 9.hours,
                       end_time: Date.new(2026, 3, 18).in_time_zone + 17.hours)
      end

      it "dots every day it spans" do
        get calendar_path(start: "2026-03-01", end: "2026-03-31")

        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>10</)
        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>14</)
        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>18</)
      end

      it "lists the event when a day within its span is selected" do
        get calendar_path(start: "2026-03-14", end: "2026-03-14")

        expect(response.body).to include(multi_day.title)
      end

      it "shows both the start and end date in the card" do
        get calendar_path(start: "2026-03-10", end: "2026-03-10")

        expect(response.body).to include(multi_day.title)
        expect(response.body).to include("10 Mar 09:00")
        expect(response.body).to include("18 Mar 17:00")
      end
    end

    context "with a very long duration event" do
      let!(:long_event) do
        create(:event, title: "Year Long Event", published: true,
                       start_time: Date.new(2026, 1, 1).in_time_zone,
                       end_time: Date.new(2027, 1, 1).in_time_zone)
      end

      it "is clamped to the grid month and dots the visible days safely" do
        get calendar_path(start: "2026-03-01", end: "2026-03-31")

        expect(response.body).to include("Year Long Event")
        # Ensure it dots days in March 2026 safely
        expect(response.body).to match(/calendar__day--has-event[^"]*"[^>]*>15</)
      end
    end

    context "with the date-range picker" do
      it "renders start and end date inputs prefilled with the range" do
        get calendar_path(start: "2026-03-10", end: "2026-03-12")

        expect(response.body).to include('name="start"')
        expect(response.body).to include('name="end"')
        expect(response.body).to include('value="2026-03-10"')
        expect(response.body).to include('value="2026-03-12"')
      end
    end
  end
end
