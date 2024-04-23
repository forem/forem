require "rails_helper"

RSpec.describe PageView do
  let(:page_view) { create(:page_view, referrer: "http://example.com/page") }
  let(:page_page_view) { create(:page_page_view, referrer: "http://example.com/page") }

  describe "article validations" do
    subject { page_view }

    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:article).optional } # Add .optional here
  end

  describe "page validations" do
    subject { page_page_view }

    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:page).optional } # Add .optional here
  end

  describe "validations" do
    # Add a new describe block for validations
    context "when both article and page are present" do
      let(:invalid_page_view) { build(:page_view, article: create(:article), page: create(:page)) }

      it "is invalid" do
        expect(invalid_page_view).not_to be_valid
        expect(invalid_page_view.errors[:base]).to include(
          "PageView must belong to either an Article or a Page, but not both",
        )
      end
    end
  end

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
