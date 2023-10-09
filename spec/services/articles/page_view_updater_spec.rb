require "rails_helper"

RSpec.describe Articles::PageViewUpdater do
  describe "#call" do
    subject(:method_call) { described_class.call(article_id: article.id, user_id: user.id) }

    let(:user) { create(:user) }

    context "when article published and written by another user" do
      let(:article) { create(:article, user: create(:user)) }

      it "updates a user's page view" do
        expect { method_call }.to change(PageView, :count)
      end
    end

    context "when article is unpublished" do
      let(:article) { create(:article, published: false, published_at: nil) }

      it "skips updating" do
        expect { method_call }.not_to change(PageView, :count)
      end
    end

    context "when article written by given user" do
      let(:article) { create(:article, user: user) }

      it "skips updating" do
        expect { method_call }.not_to change(PageView, :count)
      end
    end

    context "when time count equals EXTENDED_PAGEVIEW_NUMBER" do
      let(:article) { create(:article, user: create(:user)) }

      before do
        create(:feed_event, user: user, article: article, category: :click)
      end

      it "sends a feed event journey when it receives a page view length of 60" do
        4.times do
          described_class.call(article_id: article.id, user_id: user.id)
        end
        expect(FeedEvent.last.category).to eq("extended_pageview")
      end

      it "does not send feed event journey when it receives a page view length of less than 60" do
        2.times do
          described_class.call(article_id: article.id, user_id: user.id)
        end
        expect(FeedEvent.all.size).to be 1
      end

      it "only sends one event when it passes through the 60 range" do
        8.times do
          described_class.call(article_id: article.id, user_id: user.id)
        end
        expect(FeedEvent.all.size).to be 2
      end
    end
  end
end
