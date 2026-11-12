require "rails_helper"

RSpec.describe Articles::Destroyer, type: :service do
  let(:article) { create(:article) }
  let(:event_dispatcher) { double }

  it "destroys an article" do
    described_class.call(article)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "destroys an article whose public_reactions_count has drifted below its reactions" do
    reactor = create(:user)
    create(:reaction, reactable: article, user: reactor, category: "like")
    create(:reaction, reactable: article, user: reactor, category: "unicorn")
    create(:reaction, reactable: article, user: reactor, category: "readinglist")
    article.update_columns(public_reactions_count: 1)

    expect { described_class.call(article) }.to change { reactor.reload.reactions_count }.by(-3)
    expect(Article.find_by(id: article.id)).to be_nil
  end

  it "aggregates counter updates and skips per-reaction reactable cache purges" do
    allow(CounterCulture).to receive(:aggregate_counter_updates).and_call_original
    allow(Reactions::BustReactableCacheWorker).to receive(:new)
    create(:reaction, reactable: article, category: "like")

    described_class.call(article)

    expect(CounterCulture).to have_received(:aggregate_counter_updates)
    expect(Reactions::BustReactableCacheWorker).not_to have_received(:new)
  end

  it "schedules removing notifications if there are comments" do
    create(:comment, commentable: article)
    sidekiq_assert_enqueued_with(job: Notifications::RemoveAllWorker) do
      described_class.call(article)
    end
  end

  it "enqueues a delayed deleted-article cache bust and home-page purge for top articles", :aggregate_failures do
    organization = create(:organization)
    org_article = create(:article, organization: organization, hotness_score: 1_000_000)
    expected_attrs = Articles::BustDeletedArticleCacheWorker.attributes_for(org_article)

    described_class.call(org_article)

    expect(Articles::BustDeletedArticleCacheWorker.jobs).to include(
      hash_including("args" => [expected_attrs]),
    )
    expect(EdgeCache::PurgeByKeyWorker.jobs).to include(
      hash_including("args" => Users::DeleteArticles::HOME_PAGE_PURGE_ARGS),
    )
  end
end
