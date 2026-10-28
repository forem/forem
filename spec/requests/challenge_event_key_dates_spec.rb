require "rails_helper"

RSpec.describe "Challenge event key dates" do
  # 12:00am Pacific on November 1 and 11:59pm Pacific on November 22; both are the next day in UTC.
  let(:start_time) { Time.zone.parse("2026-11-01 07:00:00 UTC") }
  let(:end_time) { Time.zone.parse("2026-11-23 07:59:00 UTC") }
  let(:data) { { "time_zone" => "America/Los_Angeles" } }
  let(:event) { create(:event, type_of: :challenge, start_time: start_time, end_time: end_time, data: data) }

  def key_dates
    get event_path(event.event_name_slug, event.event_variation_slug)
    Nokogiri::HTML(response.body).xpath("//h3[text()='Key Dates']/following-sibling::ul/li").map do |item|
      item.css("div").map { |div| div.text.strip }
    end
  end

  it "shows the dates in the event's time zone" do
    expect(key_dates).to eq([["Contest Start", "November 01, 2026"], ["Submissions Due", "November 22, 2026"]])
  end

  it "shows the upcoming start date in the event's time zone" do
    Timecop.freeze(start_time - 1.day) do
      get event_path(event.event_name_slug, event.event_variation_slug)

      expect(response.body).to include("Starts on November 01, 2026")
    end
  end

  context "when the event has no time zone" do
    let(:data) { {} }

    it "shows the dates in the app time zone, as before" do
      expect(key_dates).to eq([["Contest Start", "November 01, 2026"], ["Submissions Due", "November 23, 2026"]])
    end
  end
end
