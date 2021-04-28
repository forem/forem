require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/articles", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get admin_articles_path }
  end

  context "when updating an Article via /admin/content_manager/articles" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:article) { create(:article) }
    let(:second_user) { create(:user) }
    let(:third_user) { create(:user) }

    before do
      sign_in super_admin
    end

    it "allows an Admin to add a co-author to an individual article" do
      get request
      expect do
        article.update_columns(co_author_ids: [1])
      end.to change(article, :co_author_ids).from([]).to([1])
    end

    it "allows an Admin to add co-authors to an individual article" do
      get request
      article.update_columns(co_author_ids: [2, 3])
      expect(article.co_author_ids).to eq([2, 3])
    end

    it "allows an Admin to mark an article as approved" do
      expect do
        patch admin_article_path(article.id), params: { article: { approved: true } }
      end.to change { article.reload.approved }.to(true)
    end

    it "allows an Admin to mark an article as featured" do
      expect do
        patch admin_article_path(article.id), params: { article: { featured: true } }
      end.to change { article.reload.featured }.to(true)
    end

    it "allows an Admin to update the published at datetime for an article" do
      updated_published_at = article.published_at - 5.hours
      expect do
        patch admin_article_path(article.id), params: { article: {
          "published_at(1i)": updated_published_at.year,
          "published_at(2i)": updated_published_at.month,
          "published_at(3i)": updated_published_at.day,
          "published_at(4i)": updated_published_at.hour,
          "published_at(5i)": updated_published_at.min,
          "published_at(6i)": updated_published_at.sec
        } }
      end.to change { article.reload.published_at }.to(DateTime.parse(updated_published_at.to_s))
    end
  end
end
