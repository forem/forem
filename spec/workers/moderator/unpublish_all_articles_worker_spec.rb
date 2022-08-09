require "rails_helper"

RSpec.describe Moderator::UnpublishAllArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  context "when unpublishing" do
    let!(:user) { create(:user) }
    let!(:articles) { create_list(:article, 3, user: user) }

    it "unpublishes all articles" do
      expect { described_class.new.perform(user.id) }.to change { user.articles.published.size }.from(3).to(0)
    end

    it "applies proper frontmatter", :aggregate_failures do
      described_class.new.perform(user.id)
      expect(Article.last.body_markdown).to include("published: false")
      expect(Article.last.body_markdown).not_to include("published: true")
    end

    it "destroys the pre-existing notifications" do
      allow(Notification).to receive(:remove_all_by_action_without_delay).and_call_original
      described_class.new.perform(user.id)
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
        described_class.new.perform(user.id)
      end.to change(ContextNotification, :count).by(-3)
    end
  end
end
