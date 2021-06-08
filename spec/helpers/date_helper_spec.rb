require "rails_helper"

describe DateHelper do
  describe ".local_date" do
    it "renders date" do
      time = Time.now.utc
      date = time.strftime("%b %-e, %Y")
      tag = helper.local_date(time)
      expect(tag).to eq "<time datetime=\"#{time.iso8601}\" class=\"date\">#{date}</time>"
    end

    it "renders date without year" do
      time = Time.now.utc
      date = time.strftime("%b %-e")
      tag = helper.local_date(time, show_year: false)
      expect(tag).to eq "<time datetime=\"#{time.iso8601}\" class=\"date-no-year\">#{date}</time>"
    end
  end
end
