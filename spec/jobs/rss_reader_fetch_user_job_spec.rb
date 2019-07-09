require "rails_helper"
require "jobs/shared_examples/enqueues_job"
require "./app/services/rss_reader"

RSpec.describe RssReaderFetchUserJob, type: :job do
  include_examples "#enqueues_job", "rss_reader_fetch_user", 456

  describe "#perform_now" do
    let(:rss_reader_service) { instance_double("RssReader") }

    before do
      allow(rss_reader_service).to receive(:fetch_user)
    end

    context "when user found and feed_url present" do
      let(:user) { double }

      before do
        allow(User).to receive(:find_by).and_return(user)
        allow(user).to receive(:feed_url).and_return(true)
      end

      it "calls the service" do
        described_class.perform_now(456, rss_reader_service)
        expect(rss_reader_service).to have_received(:fetch_user)
      end
    end

    context "when no user found" do
      it "does not call the service" do
        allow(User).to receive(:find_by)
        described_class.perform_now(456, rss_reader_service)
        expect(rss_reader_service).not_to have_received(:fetch_user)
      end
    end
  end
end
