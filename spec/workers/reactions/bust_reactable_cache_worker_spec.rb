require "rails_helper"

RSpec.describe Reactions::BustReactableCacheWorker, type: :worker do
  describe "#perform" do
    let(:user) { create(:user) }
    let(:article) { create(:article) }
    let(:reaction) { create(:reaction, reactable: article, user: user) }
    let(:comment) { create(:comment, commentable: article) }
    let(:comment_reaction) { create(:reaction, reactable: comment, user: user) }
    let(:worker) { subject }

    before do
      allow(EdgeCache::BustArticle).to receive(:call)
      allow(EdgeCache::PurgeByKey).to receive(:call)
      allow(Articles::UpdateDependentEmbedsWorker).to receive(:schedule_for_engagement)
    end

    it "busts the reactable article cache and schedules dependent embeds for public reactions" do
      worker.perform(reaction.id)
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        user.profile_identity_record_key,
        fallback_paths: [user.path],
      )
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        Reaction.surrogate_key_for_article(article.id),
        fallback_paths: "/reactions?article_id=#{article.id}",
      )
      expect(Articles::UpdateDependentEmbedsWorker).to have_received(:schedule_for_engagement).with(article.id)
    end

    it "does not schedule dependent embeds for private readinglist reactions" do
      bookmark = create(:reaction, category: "readinglist", reactable: article, user: user)
      allow(Articles::UpdateDependentEmbedsWorker).to receive(:schedule_for_engagement)

      worker.perform(bookmark.id)

      expect(Articles::UpdateDependentEmbedsWorker).not_to have_received(:schedule_for_engagement)
    end

    it "defers dependent embed scheduling on reaction destroy until after_destroy_commit" do
      target_reaction = reaction
      allow(Articles::UpdateDependentEmbedsWorker).to receive(:schedule_for_engagement)

      worker.perform(target_reaction.id, destroying: true)
      expect(Articles::UpdateDependentEmbedsWorker).not_to have_received(:schedule_for_engagement)

      target_reaction.destroy!
      expect(Articles::UpdateDependentEmbedsWorker).to have_received(:schedule_for_engagement).with(article.id)
    end

    it "busts the article if there were previously no reactions" do
      worker.perform(reaction.id)
      expect(EdgeCache::BustArticle).to have_received(:call)
    end

    it "does not bust the article or hydrate the full article row if there were previously multiple reactions" do
      create(:reaction, reactable: article, user: create(:user))
      reaction

      full_row_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql]
        if sql.include?('SELECT "articles".*') || sql.include?('SELECT "users".*')
          full_row_queries << sql
        end
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        worker.perform(reaction.id)
      end

      expect(EdgeCache::BustArticle).not_to have_received(:call)
      expect(full_row_queries).to be_empty
    end

    it "busts the reactable comment cache without hydrating full comment, article, or user rows" do
      comment_reaction

      full_row_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql]
        full_row = sql.include?('SELECT "comments".*') ||
          sql.include?('SELECT "articles".*') ||
          sql.include?('SELECT "users".*')
        full_row_queries << sql if full_row
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        worker.perform(comment_reaction.id)
      end

      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        user.profile_identity_record_key,
        fallback_paths: [user.path],
      )
      expect(EdgeCache::PurgeByKey).to have_received(:call).with(
        Reaction.surrogate_key_for_commentable(article),
        fallback_paths: "/reactions?commentable_id=#{article.id}&commentable_type=Article",
      )
      expect(full_row_queries).to be_empty
    end

    it "doesn't fail if a reaction doesn't exist" do
      expect do
        worker.perform(Reaction.maximum(:id).to_i + 1)
      end.not_to raise_error
    end
  end
end
