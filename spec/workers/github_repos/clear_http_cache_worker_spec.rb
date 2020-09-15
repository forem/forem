require "rails_helper"

RSpec.describe GithubRepos::ClearHttpCacheWorker, type: :worker do
  let(:worker) { subject }
  let(:dummy_client) { Github::OauthClient.new(client_id: "placeholder") }

  include_examples "#enqueues_on_correct_queue", "medium_priority"

  describe "#perform" do
    it "clears user/repos url http cache" do
      middleware_cache = dummy_client.middleware.handlers.detect { |h| h == Faraday::HttpCache }
      cache_build = middleware_cache.build
      storage = cache_build.__send__("storage")
      allow(Github::OauthClient).to receive(:new).and_return(dummy_client)
      allow(middleware_cache).to receive(:build).and_return(cache_build)
      allow(cache_build).to receive(:__send__).with("storage").and_return(storage)
      allow(storage).to receive(:delete)

      worker.perform
      expect(storage).to have_received(:delete).with(described_class::GITHUB_REPOS_URL)
    end
  end
end
