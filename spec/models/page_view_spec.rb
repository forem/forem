require "rails_helper"

RSpec.describe PageView do
  let(:page_view) { create(:page_view, referrer: "http://example.com/page") }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:article) }

  context "when callbacks are triggered before create" do
    describe "#domain" do
      it "is automatically set when a new page view is created" do
        expect(page_view.domain).to eq("example.com")
      end
    end

    describe "#path" do
      it "is automatically set when a new page view is created" do
        expect(page_view.path).to eq("/page")
      end
    end
  end
end
