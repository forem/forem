require "rails_helper"

vcr_option = {
  cassette_name: "se_daily_rss_feed",
  allow_playback_repeats: "true"
}

RSpec.describe Podcasts::Feed, type: :service, vcr: vcr_option do
  let(:feed_url) { "http://softwareengineeringdaily.com/feed/podcast/" }
  let(:podcast) { create(:podcast, feed_url: feed_url) }
  let(:safe_http_options) { { max_redirects: 7 } }

  before do
    # SafeHttp resolves each host before fetching; pin the public test hosts so
    # these examples don't depend on live DNS.
    allow(Addrinfo).to receive(:getaddrinfo).and_call_original
    %w[softwareengineeringdaily.com podcast.example.com].each do |host|
      allow(Addrinfo).to receive(:getaddrinfo)
        .with(host, nil, nil, :STREAM)
        .and_return([instance_double(Addrinfo, ip_address: "203.0.113.10")])
    end
    podcast
  end

  context "when unreachable" do
    let(:un_feed_url) { "http://podcast.example.com/podcast" }
    let(:unpodcast) { create(:podcast, feed_url: un_feed_url) }

    it "sets reachable and status" do
      stub_request(:get, "http://podcast.example.com/podcast").to_return(status: 200, body: "blah")
      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload
      expect(unpodcast.reachable).to be false
      expect(unpodcast.status_notice).to include("rss couldn't be parsed")
    end

    it "sets reachable" do
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast",
                                            **safe_http_options).and_raise(Errno::ECONNREFUSED)
      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload
      expect(unpodcast.reachable).to be false
      expect(unpodcast.status_notice).to include("is not reachable")
    end

    it "sets reachable when hitting ip issue" do
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast", **safe_http_options).and_raise(
        Errno::EHOSTUNREACH,
      )
      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload
      expect(unpodcast.reachable).to be false
    end

    it "sets reachable when there redirection is too deep" do
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast", **safe_http_options).and_raise(
        SafeHttp::TooManyRedirectsError, "too deep"
      )
      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload
      expect(unpodcast.reachable).to be false
    end

    it "blocks a feed URL pointing to a private or link-local IP" do
      internal_url = "http://169.254.169.254/latest/meta-data/"
      unpodcast.update_column(:feed_url, internal_url)
      stub_request(:get, internal_url).to_return(status: 200, body: "ami-id")

      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload

      expect(unpodcast.reachable).to be false
      expect(unpodcast.status_notice).to include("is not reachable")
      expect(a_request(:get, internal_url)).not_to have_been_made
    end

    it "does not follow a redirect to a private address" do
      internal_url = "http://10.0.0.5/admin"
      stub_request(:get, un_feed_url).to_return(status: 302, headers: { "Location" => internal_url })
      stub_request(:get, internal_url).to_return(status: 200, body: "secret")

      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload

      expect(unpodcast.reachable).to be false
      expect(unpodcast.status_notice).to include("is not reachable")
      expect(a_request(:get, internal_url)).not_to have_been_made
    end

    it "schedules the update url jobs when setting as unreachable" do
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast",
                                            **safe_http_options).and_raise(Errno::ECONNREFUSED)
      create_list(:podcast_episode, 2, podcast: unpodcast)

      expect do
        described_class.new(unpodcast).get_episodes(limit: 2)
      end.to change { PodcastEpisodes::UpdateMediaUrlWorker.jobs.size }.by(2)
    end

    it "re-checks episodes urls when setting as unreachable" do
      options = { timeout: Podcasts::GetMediaUrl::TIMEOUT }
      error = Errno::ECONNREFUSED
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast", **safe_http_options).and_raise(error)
      allow(SafeHttp).to receive(:head).with("http://podcast.example.com/ep1.mp3", **options).and_raise(error)
      allow(SafeHttp).to receive(:head).with("https://podcast.example.com/ep1.mp3", **options).and_raise(error)

      episode = create(:podcast_episode, podcast: unpodcast, reachable: true, media_url: "http://podcast.example.com/ep1.mp3")
      sidekiq_perform_enqueued_jobs { described_class.new(unpodcast).get_episodes }
      episode.reload

      expect(episode.reachable).to be false
    end

    it "doesn't re-check episodes reachable if the podcast was unreachable" do
      unpodcast.update_column(:reachable, false)
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast",
                                            **safe_http_options).and_raise(Errno::ECONNREFUSED)
      create_list(:podcast_episode, 2, podcast: unpodcast)
      expect do
        described_class.new(unpodcast).get_episodes(limit: 2)
      end.not_to change { PodcastEpisodes::UpdateMediaUrlWorker.jobs.size }
    end
  end

  context "when ssl certificate is not valid" do
    let(:un_feed_url) { "http://podcast.example.com/podcast" }
    let(:unpodcast) { create(:podcast, feed_url: un_feed_url) }

    it "sets ssl_failed" do
      allow(SafeHttp).to receive(:get).with("http://podcast.example.com/podcast",
                                            **safe_http_options).and_raise(OpenSSL::SSL::SSLError)
      described_class.new(unpodcast).get_episodes(limit: 2)
      unpodcast.reload
      expect(unpodcast.reachable).to be false
      expect(unpodcast.status_notice).to include("SSL certificate verify failed")
    end
  end

  context "when creating" do
    let(:cache_store) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }

    before do
      allow(Rails).to receive(:cache).and_return(cache_store)
      stub_request(:head, "https://traffic.libsyn.com/sedaily/AnalyseAsia.mp3").to_return(status: 200)
      stub_request(:head, "https://traffic.libsyn.com/sedaily/IFTTT.mp3").to_return(status: 200)
    end

    it "fetches podcast episodes" do
      expect do
        sidekiq_perform_enqueued_jobs do
          described_class.new(podcast).get_episodes(limit: 2)
        end
      end.to change(PodcastEpisode, :count).by(2)
    end

    it "fetches correct podcasts" do
      sidekiq_perform_enqueued_jobs do
        described_class.new(podcast).get_episodes(limit: 2)
      end
      episodes = podcast.podcast_episodes
      expect(episodes.pluck(:title).sort).to eq(["Analyse Asia with Bernard Leong",
                                                 "IFTTT Architecture with Nicky Leach"])
      expect(episodes.pluck(:media_url).sort).to eq(%w[https://traffic.libsyn.com/sedaily/AnalyseAsia.mp3
                                                       https://traffic.libsyn.com/sedaily/IFTTT.mp3])
    end
  end

  context "when updating" do
    let!(:episode) do
      create(:podcast_episode, media_url: "http://traffic.libsyn.com/sedaily/AnalyseAsia.mp3", title: "Old Title",
                               published_at: nil)
    end
    let!(:episode2) do
      create(:podcast_episode, media_url: "http://traffic.libsyn.com/sedaily/IFTTT.mp3", title: "SuperPodcast",
                               published_at: nil)
    end

    it "does not refetch already fetched episodes" do
      expect do
        described_class.new(podcast).get_episodes(limit: 2)
      end.not_to change(PodcastEpisode, :count)
    end

    it "updates published_at for existing episodes" do
      described_class.new(podcast).get_episodes(limit: 2)
      episode.reload
      episode2.reload
      expect(episode.published_at).to be_truthy
      expect(episode2.published_at).to be_truthy
    end
  end
end
