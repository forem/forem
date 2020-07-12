require "rails_helper"

describe DateTimeHelper do
  describe ".local_date" do
    it "renders span with date" do
      time = Time.current
      date = time.strftime("%b %e, %Y")
      tag = helper.local_date(time)
      expect(tag).to eq "<time datetime=\"#{time.iso8601}\" class=\"date\">#{date}</time>"
    end
  end
end
