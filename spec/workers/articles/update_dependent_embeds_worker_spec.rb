require "rails_helper"

RSpec.describe Articles::UpdateDependentEmbedsWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1

  describe ".schedule_for_engagement" do
    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_cache)
      allow(described_class).to receive(:perform_in)
    end

    it "returns false and enqueues nothing when the article has no dependent embeds" do
      article = create(:article)

      expect(described_class.schedule_for_engagement(article.id)).to be(false)
      expect(described_class).not_to have_received(:perform_in)
    end

    it "uses a 15-second priority debounce window for active Billboards and coalesces bursts" do
      article = create(:article)
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{article.path} %}",
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)

      expect(described_class.schedule_for_engagement(article.id)).to be(true)
      expect(described_class.schedule_for_engagement(article.id)).to be(false)

      expect(described_class).to have_received(:perform_in)
        .with(described_class::BILLBOARD_ENGAGEMENT_DEBOUNCE, article.id)
        .once
    end

    it "uses a 60-second debounce window for non-billboard embeds and resets the window once perform runs" do
      target = create(:article)
      holder = create(:published_article, title: "Holder Post", body_markdown: "Check out:\n{% link #{target.path} %}")
      SyncLiquidEmbedReferencesWorker.new.perform("Article", holder.id)

      expect(described_class.schedule_for_engagement(target.id)).to be(true)
      expect(described_class.schedule_for_engagement(target.id)).to be(false)
      expect(described_class).to have_received(:perform_in)
        .with(described_class::DEFAULT_ENGAGEMENT_DEBOUNCE, target.id)
        .once

      described_class.new.perform(target.id)

      expect(described_class.schedule_for_engagement(target.id)).to be(true)
      expect(described_class).to have_received(:perform_in)
        .with(described_class::DEFAULT_ENGAGEMENT_DEBOUNCE, target.id)
        .twice
    end

    it "scales debounce exponentially by embedder age for < 24h content" do
      target = create(:article)
      holder = create(:published_article, title: "Two Hour Holder", body_markdown: "{% link #{target.path} %}")
      holder.update_columns(published_at: 2.hours.ago, created_at: 2.hours.ago)
      SyncLiquidEmbedReferencesWorker.new.perform("Article", holder.id)

      expect(described_class.schedule_for_engagement(target.id)).to be(true)
      expect(described_class).to have_received(:perform_in).with(4.minutes, target.id).once
    end

    it "applies an exponential post-refresh cooldown on older content to avoid sending to Sidekiq at all" do
      target = create(:article)
      target.update_columns(published_at: 200.days.ago, created_at: 200.days.ago)
      holder = create(:published_article, title: "Archive Holder", body_markdown: "{% link #{target.path} %}")
      holder.update_columns(published_at: 200.days.ago, created_at: 200.days.ago)
      SyncLiquidEmbedReferencesWorker.new.perform("Article", holder.id)

      # Cold start coalesces over COLD_COALESCE_WINDOW (2 minutes) rather than holding a 72h Sidekiq job
      expect(described_class.schedule_for_engagement(target.id)).to be(true)
      expect(described_class).to have_received(:perform_in)
        .with(described_class::COLD_COALESCE_WINDOW, target.id)
        .once

      # Running perform activates the 72-hour exponential cooldown in Rails.cache
      described_class.new.perform(target.id)

      # Subsequent engagement events during the 72-hour cooldown do not touch Sidekiq at all
      expect(described_class.schedule_for_engagement(target.id)).to be(false)
      Timecop.travel(48.hours.from_now) do
        expect(described_class.schedule_for_engagement(target.id)).to be(false)
      end
      expect(described_class).to have_received(:perform_in).once

      # After the 72-hour cooldown expires, a new engagement event can schedule again
      Timecop.travel(73.hours.from_now) do
        expect(described_class.schedule_for_engagement(target.id)).to be(true)
      end
      expect(described_class).to have_received(:perform_in).twice
    end

    it "keeps the debounce reservation until perform starts even if poller/queue latency exceeds delay" do
      article = create(:article)
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{article.path} %}",
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)

      expect(described_class.schedule_for_engagement(article.id)).to be(true)

      # 25s later (> 15s delay), Sidekiq hasn't executed perform yet: must NOT reschedule and starve
      Timecop.travel(25.seconds.from_now) do
        expect(described_class.schedule_for_engagement(article.id)).to be(false)
      end
      expect(described_class).to have_received(:perform_in).once

      # Once perform actually runs, the reservation clears so subsequent engagement can schedule
      Timecop.travel(26.seconds.from_now) do
        described_class.new.perform(article.id)
        expect(described_class.schedule_for_engagement(article.id)).to be(true)
      end
      expect(described_class).to have_received(:perform_in).twice
    end

    it "isolates structural and engagement lock_args and uses log conflict strategy on engagement pushes" do
      expect(described_class.lock_args([42, { "org_ids" => [1], "structural" => true }])).to eq([42, "structural"])
      expect(described_class.lock_args([42])).to eq([42, "engagement"])

      described_class.jobs.clear
      allow(described_class).to receive(:perform_in).and_call_original
      allow(described_class).to receive(:perform_async).and_call_original

      article = create(:article)
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{article.path} %}",
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      described_class.jobs.clear
      memory_cache.clear

      described_class.schedule_for_engagement(article.id)
      memory_cache.clear
      described_class.schedule_for_article_change(article.id, membership_changed: false)

      engagement_item = described_class.jobs.detect { |i| i["args"] == [article.id] }
      structural_item = described_class.jobs.detect { |i| i["args"].second.is_a?(Hash) }
      expect(engagement_item["on_conflict"]).to eq("log")
      expect(structural_item["on_conflict"].to_s).to eq("replace")
    end
  end

  describe ".schedule_for_article_change" do
    let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(memory_cache)
      allow(described_class).to receive(:perform_async)
    end

    it "merges consecutive organization and tag removals in pending cache context" do
      org = create(:organization, slug: "mergedorg")
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% feed org=mergedorg %}",
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      article = create(:article, organization: org, tag_list: "")
      memory_cache.clear

      described_class.schedule_for_article_change(
        article.id,
        organization_ids: [org.id],
        tag_names: ["ruby"],
        membership_changed: true,
      )
      # Simulate a follow-up title edit after org removal before worker executes
      article.update_column(:organization_id, nil)
      LiquidEmbedReference.create!(
        record: billboard,
        tag_name: "link",
        url: article.path,
        options: article.path,
        referenced: article,
        published: true,
      )
      described_class.schedule_for_article_change(
        article.id,
        organization_ids: [],
        tag_names: ["rails"],
        membership_changed: false,
      )

      expect(described_class).to have_received(:perform_async).with(
        article.id,
        {
          "org_ids" => [org.id],
          "tags" => %w[ruby rails],
          "membership_changed" => true,
          "structural" => true
        },
      )
    end
  end

  describe "#perform" do
    it "refreshes Billboards first, preserves ?bb= params, updates metadata, and purges Fastly", :aggregate_failures do
      org = create(:organization, slug: "prioritybborg")
      article = create(:article, organization: org, title: "Initial Title", published: true)

      billboard = create(
        :billboard,
        approved: true,
        published: true,
        placement_area: "feed_first",
        special_behavior: :persistent,
        render_mode: :forem_markdown,
        body_markdown: "{% feed org=prioritybborg limit=3 %}",
        minimized_body_markdown: "{% link #{article.path} %}",
      )
      holder_article = create(
        :published_article,
        title: "Holder Post",
        body_markdown: "Post embed:\n{% link #{article.path} %}",
      )
      holder_comment = create(:comment, body_markdown: "Comment embed:\n{% link #{article.path} %}")

      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      SyncLiquidEmbedReferencesWorker.new.perform("Article", holder_article.id)
      SyncLiquidEmbedReferencesWorker.new.perform("Comment", holder_comment.id)

      allow(EdgeCache::PurgeByKey).to receive(:call)
      new_article = create(:article, organization: org, title: "Brand New Org Launch", published: true)
      original_content_updated_at = billboard.content_updated_at

      update_tables_order = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        if sql.start_with?('UPDATE "display_ads"')
          update_tables_order << "Billboard"
        elsif sql.start_with?('UPDATE "articles"')
          update_tables_order << "Article"
        elsif sql.start_with?('UPDATE "comments"')
          update_tables_order << "Comment"
        end
      end

      Timecop.travel(5.minutes.from_now) do
        described_class.new.perform(
          new_article.id,
          { "org_ids" => [org.id], "tags" => [], "membership_changed" => true },
        )
        article.update_column(:title, "Updated Linked Title")
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          described_class.new.perform(article.id)
        end
      end

      billboard.reload
      holder_article.reload
      holder_comment.reload

      expect(update_tables_order).to eq(%w[Billboard Article Comment])
      expect(billboard.processed_html).to include("Brand New Org Launch", "bb=#{billboard.id}")
      expect(billboard.minimized_processed_html).to include("Updated Linked Title")
      expect(billboard.exclude_article_ids).to include(new_article.id)
      expect(billboard.content_updated_at).to be > original_content_updated_at
      expect(holder_article.processed_html).to include("Updated Linked Title")
      expect(holder_comment.processed_html).to include("Updated Linked Title")
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(billboard.record_key).at_least(:once)
      expect(EdgeCache::PurgeByKey).to have_received(:call)
        .with("main_app_home_page", fallback_paths: "/")
        .at_least(:once)
    end

    it "updates {% feed tag=... %} embeds and skips non-displayed articles on sort=recent feeds" do
      create(:tag, name: "featuredtag")
      older = create(:article, title: "Older Tagged Post", tag_list: "featuredtag", published: true)
      older.update_columns(published_at: 2.hours.ago)
      displayed = create(:article, title: "Newest Tagged Post", tag_list: "featuredtag", published: true)
      displayed.update_columns(published_at: 1.minute.ago)

      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% feed tag=featuredtag limit=1 %}",
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      expect(billboard.processed_html).to include("Newest Tagged Post")
      expect(billboard.processed_html).not_to include("Older Tagged Post")

      # Engagement on an older post NOT in the top-1 recent feed skips ContentRenderer completely
      allow(ContentRenderer).to receive(:new).and_call_original
      described_class.new.perform(older.id)
      expect(ContentRenderer).not_to have_received(:new)

      # Engagement on the displayed top-1 post refreshes the billboard
      displayed.update_columns(public_reactions_count: 12)
      described_class.new.perform(displayed.id)

      expect(billboard.reload.processed_html).to include("12")
    end

    it "removes deleted articles from dependent embeds and feeds" do
      org = create(:organization, slug: "deletefeedorg")
      doomed = create(:article, organization: org, title: "Soon Deleted Post", published: true)
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% feed org=deletefeedorg limit=3 %}",
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      expect(billboard.processed_html).to include("Soon Deleted Post")

      doomed_id = doomed.id
      doomed.destroy!
      described_class.new.perform(
        doomed_id,
        { "org_ids" => [org.id], "tags" => [], "membership_changed" => true },
      )

      expect(billboard.reload.processed_html).not_to include("Soon Deleted Post")
    end

    it "isolates errors per record so a failing record never prevents other embeds from updating" do
      target = create(:article, title: "Before Isolation")
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{target.path} %}",
      )
      broken_page = create(:page, body_markdown: "{% link #{target.path} %}")
      healthy_comment = create(:comment, body_markdown: "{% link #{target.path} %}")

      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      SyncLiquidEmbedReferencesWorker.new.perform("Page", broken_page.id)
      SyncLiquidEmbedReferencesWorker.new.perform("Comment", healthy_comment.id)

      allow(Pages::BustCacheWorker).to receive(:perform_async).and_raise(StandardError, "redis timeout")
      target.update_column(:title, "After Isolation")

      expect { described_class.new.perform(target.id) }.not_to raise_error
      expect(billboard.reload.processed_html).to include("After Isolation")
      expect(healthy_comment.reload.processed_html).to include("After Isolation")
    end

    it "does not trigger async_bust or DB updates if rendered HTML did not change" do
      target = create(:article, title: "Unchanged Title")
      holder = create(:published_article, title: "Holder Title", body_markdown: "{% link #{target.path} %}")
      SyncLiquidEmbedReferencesWorker.new.perform("Article", holder.id)

      allow(Articles::BustCacheWorker).to receive(:perform_async)
      update_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        update_queries << sql if sql.start_with?('UPDATE "articles"')
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.new.perform(target.id)
      end

      expect(Articles::BustCacheWorker).not_to have_received(:perform_async)
      expect(update_queries).to be_empty
    end

    it "refreshes template-backed Pages via render_from_page_template when embedded articles change" do
      target = create(:article, title: "Template Initial Title")
      page_template = create(:page_template)
      page = create(
        :page,
        page_template: page_template,
        body_markdown: nil,
        template_data: { "title" => "Hub", "content" => "{% link #{target.path} %}" },
      )
      SyncLiquidEmbedReferencesWorker.new.perform("Page", page.id)
      expect(page.processed_html).to include("Template Initial Title")

      target.update_column(:title, "Template Updated Title")
      described_class.new.perform(target.id)

      expect(page.reload.processed_html).to include("Template Updated Title")
    end

    it "refreshes active Billboards every time while backing off co-dependent archive Articles on engagement" do
      memory_cache = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_cache)

      target = create(:article, title: "Shared Target")
      billboard = create(
        :billboard,
        approved: true,
        published: true,
        render_mode: :forem_markdown,
        body_markdown: "{% link #{target.path} %}",
      )
      archive_holder = create(:published_article, title: "Old Archive", body_markdown: "{% link #{target.path} %}")
      archive_holder.update_columns(published_at: 120.days.ago, created_at: 120.days.ago)

      SyncLiquidEmbedReferencesWorker.new.perform("Billboard", billboard.id)
      SyncLiquidEmbedReferencesWorker.new.perform("Article", archive_holder.id)

      # First engagement burst updates both the live Billboard and the cold archive Article
      target.update_columns(public_reactions_count: 4_321)
      described_class.new.perform(target.id, { "engagement" => true })
      expect(billboard.reload.processed_html).to include("4321")
      expect(archive_holder.reload.processed_html).to include("4321")

      # Second engagement burst 1 minute later refreshes the Billboard immediately,
      # while per-record exponential backoff skips re-rendering the 120-day-old archive Article
      target.update_columns(public_reactions_count: 8_765)
      described_class.new.perform(target.id, { "engagement" => true })
      expect(billboard.reload.processed_html).to include("8765")
      expect(archive_holder.reload.processed_html).not_to include("8765")

      # Authoritative structural edit (title change) bypasses engagement backoff immediately
      target.update_columns(title: "Renamed Target Post")
      described_class.new.perform(
        target.id,
        { "org_ids" => [], "tags" => [], "membership_changed" => false, "structural" => true },
      )
      expect(archive_holder.reload.processed_html).to include("Renamed Target Post", "8765")
    end

    it "refreshes sort=score feeds when a private readinglist reaction moves an article across a limit=1 boundary",
       :aggregate_failures do
      org = create(:organization, slug: "scoresortorg")
      leader = create(:published_article, organization: org, title: "Score Leader Post")
      challenger = create(:published_article, organization: org, title: "Score Challenger Post")
      established_reader1 = create(:user, registered_at: 30.days.ago)
      established_reader2 = create(:user, registered_at: 30.days.ago)
      established_reader3 = create(:user, registered_at: 30.days.ago)

      Sidekiq::Testing.inline! do
        leader.update_score
        challenger.update_score
        create(:reaction, category: "readinglist", reactable: leader, user: established_reader1)
      end
      expect(leader.reload.score).to be > challenger.reload.score

      billboard = Sidekiq::Testing.inline! do
        create(
          :billboard,
          approved: true,
          published: true,
          render_mode: :forem_markdown,
          body_markdown: "{% feed org=scoresortorg sort=score limit=1 %}",
        )
      end
      expect(billboard.reload.processed_html).to include("Score Leader Post")
      expect(billboard.processed_html).not_to include("Score Challenger Post")

      # Two private readinglist bookmarks push challenger ahead of leader in score
      bookmarks = Sidekiq::Testing.inline! do
        [
          create(:reaction, category: "readinglist", reactable: challenger, user: established_reader2),
          create(:reaction, category: "readinglist", reactable: challenger, user: established_reader3),
        ]
      end
      expect(challenger.reload.score).to be > leader.reload.score
      expect(billboard.reload.processed_html).to include("Score Challenger Post")
      expect(billboard.processed_html).not_to include("Score Leader Post")

      # Destroying those private bookmarks drops challenger back below leader and refreshes the feed
      Sidekiq::Testing.inline! do
        bookmarks.each(&:destroy!)
      end
      expect(leader.reload.score).to be > challenger.reload.score
      expect(billboard.reload.processed_html).to include("Score Leader Post")
      expect(billboard.processed_html).not_to include("Score Challenger Post")
    end

    it "resyncs Page references when a shared PageTemplate's body_markdown is edited or cleared of embeds" do
      post_a = create(:published_article, title: "Shared Template Post A")
      post_b = create(:published_article, title: "Shared Template Post B")

      page_template, page = Sidekiq::Testing.inline! do
        tmpl = create(:page_template, body_markdown: "<div>{% link #{post_a.path} %}</div>")
        pg = create(:page, page_template: tmpl, body_markdown: nil, template_data: { "title" => "Hub" })
        [tmpl, pg]
      end
      expect(page.liquid_embed_references.pluck(:referenced_id)).to eq([post_a.id])

      # Edit shared PageTemplate from Post A -> Post B and run ReRenderPagesWorker
      Sidekiq::Testing.inline! do
        page_template.update!(body_markdown: "<div>{% link #{post_b.path} %}</div>")
      end
      expect(page.liquid_embed_references.reload.pluck(:referenced_id)).to eq([post_b.id])

      post_b.update_column(:title, "Updated Shared Template Post B")
      described_class.new.perform(post_b.id)
      expect(page.reload.processed_html).to include("Updated Shared Template Post B")

      # Remove the last Liquid embed from the shared PageTemplate
      Sidekiq::Testing.inline! do
        page_template.update!(body_markdown: "<div>Plain static template</div>")
      end
      expect(page.liquid_embed_references.reload).to be_empty
    end

    it "tracks {% feed tag=... %} created before the Tag exists and refreshes when the first post is published" do
      tag_name = "brandnewtopic#{SecureRandom.hex(3)}"
      expect(Tag.find_by(name: tag_name)).to be_nil

      billboard = Sidekiq::Testing.inline! do
        create(
          :billboard,
          approved: true,
          published: true,
          render_mode: :forem_markdown,
          body_markdown: "{% feed tag=#{tag_name} %}",
        )
      end
      ref = billboard.liquid_embed_references.first
      expect(ref.referenced_type).to eq("Tag")
      expect(ref.referenced_id).to be_nil

      first_article = Sidekiq::Testing.inline! do
        create(:published_article, title: "Inaugural Topic Post", tag_list: tag_name)
      end

      created_tag = Tag.find_by!(name: tag_name)
      expect(ref.reload.referenced_id).to eq(created_tag.id)
      expect(billboard.reload.processed_html).to include(first_article.title)
    end
  end

  describe "#perform with a persisted source article" do
    it "reads only narrow metadata columns from the source article instead of hydrating the full row" do
      source_article = create(:article, organization: create(:organization))
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.new.perform(source_article.id)
      end

      article_selects = queries.grep(/FROM "articles"/)
      expected_prefix = 'SELECT "articles"."id", "articles"."organization_id", ' \
                        '"articles"."cached_tag_list" FROM "articles"'
      expect(article_selects).not_to be_empty
      expect(article_selects).to all(start_with(expected_prefix))
    end
  end
end
