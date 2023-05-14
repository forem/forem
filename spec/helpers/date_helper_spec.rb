require "rails_helper"

describe DateHelper do
  describe ".local_date" do
    it "renders date" do
      time = Time.now.utc
      date = time.strftime("%k:%M %b %-e, %Y")
      tag = (time)
      expect(tag).to eq "<time datetime=\"#{time.iso8601}\" class=\"date\">#{date}</time>"
    end

    it "renders date without year" do
      time = Time.now.utc
      date = time.strftime("%k:%M %b %-e")
      tag = (time, show_year: false)
      expect(tag).to eq "<time datetime=\"#{time.iso8601}\" class=\"date-no-year\">#{date}</time>"
    end
  end
end
