require "rails_helper"

RSpec.describe "Challenge event status" do
  let(:start_time) { Time.zone.parse("2026-11-01 12:00:00") }
  let(:end_time) { start_time + 1.week }
  let(:event) { create(:event, type_of: :challenge, start_time: start_time, end_time: end_time) }

  it "shows the upcoming start date" do
    Timecop.freeze(start_time - 1.day) do
      get event_path(event.event_name_slug, event.event_variation_slug)

      expect(response.body).to include("Starts on November 01, 2026")
    end
  end

  [
    ["before the start", -1, "UPCOMING"],
    ["at the start", 0, "LIVE"],
    ["during the challenge", 1.day, "LIVE"],
    ["at the end", 1.week, "LIVE"],
    ["after the end", 1.week + 1, "ENDED"],
  ].each do |description, offset, status|
    it "shows #{status} #{description}" do
      Timecop.freeze(start_time + offset) do
        get event_path(event.event_name_slug, event.event_variation_slug)

        expect(response).to have_http_status(:ok)
        badge = Nokogiri::HTML(response.body).at_css("header .mt-4 span:nth-child(2)")
        expect(badge.text).to eq(status)
      end
    end
  end
end
