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
  end
end
