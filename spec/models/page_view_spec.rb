require "rails_helper"

RSpec.describe PageView, type: :model do
  let(:article) { create(:article) }
  let(:job_class) { TweetTagRefreshStatsJob }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to belong_to(:article) }

  # rubocop:disable RSpec/AnyInstance
  def mock_random_method
    allow_any_instance_of(described_class).
      to receive(:rand).with(30).and_return(1)
  end
  # rubocop:enable RSpec/AnyInstance

  describe "#domain" do
    it "is automatically set when a new page view is created" do
      pv = create(:page_view, referrer: "http://example.com/page")
      expect(pv.reload.domain).to eq("example.com")
    end
  end

  describe "#path" do
    it "is automatically set when a new page view is created" do
      pv = create(:page_view, referrer: "http://example.com/page")
      expect(pv.reload.path).to eq("/page")
    end
  end

  describe "after create hook" do
    it "calls TweetTagRefreshStatsJob" do
      mock_random_method

      expect { create(:page_view, article: article) }.
        to have_enqueued_job.on_queue(job_class.queue_name).with(article.id)
    end
  end
end
