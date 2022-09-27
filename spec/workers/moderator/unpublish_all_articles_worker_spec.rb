require "rails_helper"

RSpec.describe Moderator::UnpublishAllArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  context "when unpublishing" do
    let!(:user) { create(:user) }
    let!(:admin) { create(:user, :admin) }
    let!(:articles) { create_list(:article, 3, user: user) }
    let!(:comments) { create_list(:comment, 3, user: user, commentable: articles.sample) }

    it "unpublishes all articles" do
      expect do
        described_class.new.perform(user.id, admin.id)
      end.to change { user.articles.published.size }.from(3).to(0)
    end

    it "unpublishes related comments" do
      expect do
        described_class.new.perform(user.id, admin.id)
      end.to change { user.comments.where(deleted: false).size }.from(3).to(0)
    end

    it "applies proper frontmatter", :aggregate_failures do
      described_class.new.perform(user.id, admin.id)
      articles.each(&:reload)
      expect(articles.map { |a| a.body_markdown.include?("published: false") }.uniq).to eq([true])
      expect(articles.map { |a| a.body_markdown.include?("published: true") }.uniq).to eq([false])
    end

    it "destroys the pre-existing notifications" do
      allow(Notification).to receive(:remove_all_by_action_without_delay).and_call_original
      described_class.new.perform(user.id, admin.id)
      articles.map(&:id).each do |id|
        attrs = { notifiable_ids: id, notifiable_type: "Article", action: "Published" }
        expect(Notification).to have_received(:remove_all_by_action_without_delay).with(attrs)
      end
    end

    it "destroys the pre-existing context notifications" do
      articles.each do |article|
        create(:context_notification, context: article, action: "Published")
      end
      expect do
        described_class.new.perform(user.id, admin.id)
      end.to change(ContextNotification, :count).by(-3)
    end

    it "creates audit_log records" do
      Audit::Subscribe.listen :admin_api

      expect do
        described_class.new.perform(user.id, admin.id)
      end.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
      expect(log.data["action"]).to eq("api_user_unpublish")
      expect(log.user_id).to eq(admin.id)

      expect(log.data["target_article_ids"]).to match_array(articles.map(&:id))
      expect(log.data["target_comment_ids"]).to match_array(comments.map(&:id))
    end

    it "creates audit_log records for admin action" do
      Audit::Subscribe.listen :moderator

      expect do
        described_class.new.perform(user.id, admin.id, "moderator")
      end.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
      expect(log.data["action"]).to eq("unpublish_all_articles")
      expect(log.user_id).to eq(admin.id)
    end
  end
end
