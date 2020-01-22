require "rails_helper"

RSpec.describe PageView, type: :model do
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

  describe "indexing" do
    it "indexes updated records" do
      sidekiq_assert_enqueued_with(job: Search::IndexWorker, args: ["PageView", page_view.id]) do
        page_view.update(path: "/")
      end
    end

    it "removes deleted records" do
      expect do
        page_view.destroy
      end.to have_enqueued_job(Search::RemoveFromIndexJob).exactly(:once).with(described_class.algolia_index_name, page_view.id)
    end
  end
end
