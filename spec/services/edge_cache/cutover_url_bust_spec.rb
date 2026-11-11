require "rails_helper"

RSpec.describe EdgeCache::CutoverUrlBust, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:deploy_time) { Time.utc(2026, 11, 12, 12, 0, 0) }

  before do
    described_class.reset!
    Rails.cache.delete(described_class::CACHE_KEY)
    allow(ApplicationConfig).to receive(:[]).and_call_original
  end

  after do
    described_class.reset!
    Rails.cache.delete(described_class::CACHE_KEY)
  end

  context "when Fastly is not configured" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)
    end

    it "is inactive, skips lazy callables, and enqueues no jobs", :aggregate_failures do
      evaluated = false
      travel_to(deploy_time) do
        expect(described_class.active?).to be(false)
        sidekiq_assert_no_enqueued_jobs(only: EdgeCache::CutoverUrlBustWorker) do
          described_class.call(lambda {
            evaluated = true
            ["/tags"]
          })
        end
      end

      expect(evaluated).to be(false)
    end
  end

  context "when Fastly is configured" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("fake-key")
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("fake-service")
    end

    it "enqueues CutoverUrlBustWorker during the 50-hour window and auto-expires afterward", :aggregate_failures do
      travel_to(deploy_time) do
        sidekiq_assert_enqueued_with(
          job: EdgeCache::CutoverUrlBustWorker,
          args: [["/tags", "/async_info/navigation_links"]],
        ) do
          described_class.call(["/tags", " /async_info/navigation_links ", "/tags", nil])
        end
      end

      travel_to(deploy_time + 49.hours) do
        expect(described_class.active?).to be(true)
      end

      travel_to(deploy_time + 50.hours + 1.second) do
        expect(described_class.active?).to be(false)
        sidekiq_assert_no_enqueued_jobs(only: EdgeCache::CutoverUrlBustWorker) do
          described_class.call("/tags")
        end
      end
    end

    it "stays inactive past HARD_CUTOFF_AT even if Rails.cache was cleared" do
      travel_to(described_class::HARD_CUTOFF_AT + 1.minute) do
        Rails.cache.delete(described_class::CACHE_KEY)
        described_class.reset!

        expect(described_class.active?).to be(false)
      end
    end

    it "honors explicit EDGE_CACHE_CUTOVER_URL_BUST overrides", :aggregate_failures do
      travel_to(deploy_time) do
        allow(ApplicationConfig).to receive(:[]).with("EDGE_CACHE_CUTOVER_URL_BUST").and_return("false")
        expect(described_class.active?).to be(false)
      end

      travel_to(described_class::HARD_CUTOFF_AT + 1.day) do
        allow(ApplicationConfig).to receive(:[]).with("EDGE_CACHE_CUTOVER_URL_BUST").and_return("true")
        expect(described_class.active?).to be(true)
      end
    end

    it "chunks large path lists and supports delayed scheduling", :aggregate_failures do
      paths = (1..60).map { |i| "/org/post-#{i}" }

      travel_to(deploy_time) do
        sidekiq_assert_enqueued_jobs(2, only: EdgeCache::CutoverUrlBustWorker) do
          described_class.call(-> { paths }, delay: 10.seconds)
        end
      end
    end

    it "supplements newly-tagged route busts during cutover", :aggregate_failures do
      allow(EdgeCache::PurgeByKey).to receive(:call)
      org = create(:organization)
      author = create(:user)
      author.update_columns(old_username: "legacyauthor")
      article = create(:article, user: author, organization: org, published: true)
      EdgeCache::CutoverUrlBustWorker.jobs.clear

      travel_to(deploy_time) do
        EdgeCache::BustArticle.call(article)
        Users::BustProfileIdentityCacheWorker.new.perform(author.id)
        EdgeCache::BustPage.call("security")
        EdgeCache::BustTag.call(create(:tag, name: "rustlang"))
      end

      enqueued_paths = EdgeCache::CutoverUrlBustWorker.jobs.flat_map { |job| job["args"].first }
      expect(enqueued_paths).to include(
        "/bottom_items?article_id=#{article.id}",
        "/#{author.username}/#{article.slug}",
        "/legacyauthor/#{article.slug}",
        "/legacyauthor",
        "/page/security",
        "/security/",
        "/bounty",
        "/t/rustlang",
        "/tags",
      )
    end
  end
end
