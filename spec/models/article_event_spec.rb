require "rails_helper"

RSpec.describe Article do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }
  let(:event_resource_admin) do
    create(:user).tap { |u| u.add_role(:single_resource_admin, Event) }
  end

  let(:live_event) do
    create(:event, published: true, allow_articles: true,
                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
  end
  let(:upcoming_event) do
    create(:event, published: true, allow_articles: true,
                   start_time: 1.hour.from_now, end_time: 3.hours.from_now)
  end
  let(:ended_event) do
    create(:event, published: true, allow_articles: true,
                   start_time: 3.hours.ago, end_time: 1.hour.ago)
  end
  let(:draft_live_event) do
    create(:event, published: false, allow_articles: true,
                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
  end
  let(:disabled_live_event) do
    create(:event, published: true, allow_articles: false,
                   start_time: 1.hour.ago, end_time: 1.hour.from_now)
  end

  describe "event assignment validations" do
    it "allows regular users to tag an article while a published event allowing articles is live" do
      article = build(:article, user: user, event: live_event)
      expect(article).to be_valid
      expect { article.save! }.not_to raise_error
      expect(article.reload.event).to eq(live_event)
    end

    it "rejects tagging when event does not exist" do
      article = build(:article, user: user, event_id: -1)
      expect(article).not_to be_valid
      expect(article.errors[:event_id]).to include(I18n.t("models.article.event_not_found"))
    end

    it "rejects tagging when event has allow_articles disabled for both regular users and admins" do
      regular_article = build(:article, user: user, event: disabled_live_event)
      admin_article = build(:article, user: admin, event: disabled_live_event)
      console_admin_article = build(:article, user: user, event: disabled_live_event, admin_update: true)

      [regular_article, admin_article, console_admin_article].each do |article|
        expect(article).not_to be_valid
        expect(article.errors[:event_id]).to include(I18n.t("models.article.event_articles_disabled"))
      end
    end

    it "rejects regular users tagging before, after, or on an unpublished event" do
      [upcoming_event, ended_event, draft_live_event].each do |event|
        article = build(:article, user: user, event: event)
        expect(article).not_to be_valid
        expect(article.errors[:event_id]).to include(I18n.t("models.article.event_not_accepting_articles"))
      end
    end

    it "allows admins and admin_update to tag before, during, after, and on draft events" do
      [upcoming_event, live_event, ended_event, draft_live_event].each do |event|
        expect(build(:article, user: admin, event: event)).to be_valid
        expect(build(:article, user: event_resource_admin, event: event)).to be_valid
        expect(build(:article, user: user, event: event, admin_update: true)).to be_valid
      end
    end

    it "allows editing and untagging an already-tagged article after the event ends or disables articles" do
      article = create(:article, user: user, event: live_event, published: true)
      live_event.update!(start_time: 3.hours.ago, end_time: 1.hour.ago, allow_articles: false)

      expect(article.update(title: "Updated Post Title After Event")).to be(true)
      expect(article.reload.event_id).to eq(live_event.id)

      expect(article.update(event: nil)).to be(true)
      expect(article.reload.event_id).to be_nil
    end

    it "does not expose event_id through ArticlePolicy#permitted_attributes" do
      policy = ArticlePolicy.new(user, build(:article, user: user))
      expect(policy.permitted_attributes).not_to include(:event_id)
    end
  end

  describe "#visible_event and #event_visible?" do
    it "returns nil and avoids querying events when event_id is blank" do
      article = create(:article, user: user, event: nil)
      event_queries = 0
      callback = lambda do |*, payload|
        event_queries += 1 if payload[:sql].include?('FROM "events"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(article.visible_event).to be_nil
        expect(article.event_visible?).to be(false)
      end

      expect(event_queries).to eq(0)
    end

    it "hides pre-tagged upcoming, unpublished, or disabled events and shows live and ended events" do
      pre_tagged = create(:article, user: admin, event: upcoming_event)
      expect(pre_tagged.visible_event).to be_nil
      expect(pre_tagged.event_visible?).to be(false)

      draft_tagged = create(:article, user: admin, event: draft_live_event)
      expect(draft_tagged.visible_event).to be_nil

      live_tagged = create(:article, user: user, event: live_event)
      expect(live_tagged.visible_event).to eq(live_event)
      expect(live_tagged.event_visible?).to be(true)

      ended_tagged = create(:article, user: admin, event: ended_event)
      expect(ended_tagged.visible_event).to eq(ended_event)
      expect(ended_tagged.event_visible?).to be(true)

      live_event.update!(allow_articles: false)
      expect(live_tagged.reload.visible_event).to be_nil
    end
  end

  describe "event edge cache invalidation" do
    it "includes the event record_key and path in EdgeCache::BustArticle when tagged" do
      article = create(:article, user: user, event: live_event, published: true)
      allow(EdgeCache::PurgeByKey).to receive(:call)

      EdgeCache::BustArticle.call(article)

      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        array_including(article.record_key, live_event.record_key),
        fallback_paths: array_including(article.path, live_event.path),
      )
    end

    it "purges the previous event when an article is untagged or moved to another event" do
      article = create(:article, user: user, event: live_event, published: true)
      allow(EdgeCache::PurgeByKeyWorker).to receive(:perform_async)

      article.update!(event: nil)

      expect(EdgeCache::PurgeByKeyWorker).to have_received(:perform_async).with(
        live_event.record_key,
        [live_event.path],
      )
    end

    it "captures event_id in Articles::BustDeletedArticleCacheWorker so event cache is busted on destroy" do
      article = create(:article, user: user, event: live_event, published: true)
      attrs = Articles::BustDeletedArticleCacheWorker.attributes_for(article)

      expect(attrs["event_id"]).to eq(live_event.id)

      allow(EdgeCache::PurgeByKey).to receive(:call)
      Articles::BustDeletedArticleCacheWorker.new.perform(attrs)

      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        array_including(live_event.record_key),
        fallback_paths: array_including(live_event.path),
      )
    end
  end

  describe "event schema constraints and indexes" do
    it "has a valid partial composite index for event article feeds" do
      index = ActiveRecord::Base.connection.indexes(:articles).detect do |idx|
        idx.name == "index_articles_on_event_id_published_hotness_published_at"
      end

      expect(index).to be_present
      expect(index).to be_valid
      expect(index.using).to eq(:btree)
      expect(index.columns).to eq(%w[event_id published hotness_score published_at])
      expect(index.orders).to eq("hotness_score" => :desc, "published_at" => :desc)
      expect(index.where).to eq("(event_id IS NOT NULL)")
    end

    it "has a validated foreign key from articles.event_id to events" do
      fk = ActiveRecord::Base.connection.foreign_keys(:articles).detect do |key|
        key.to_table == "events" && key.column == "event_id"
      end

      expect(fk).to be_present
      expect(fk).to be_validated
      expect(fk.on_delete).to eq(:nullify)
    end
  end
end
