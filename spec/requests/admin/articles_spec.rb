require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/content_manager/articles", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article) }

  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get admin_articles_path }
  end

  context "when updating an article via /admin/content_manager/articles" do
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

    it "allows an Admin to mark an article as pinned" do
      decorated_article = article.decorate

      expect do
        patch admin_article_path(article.id), params: { article: { pinned: true } }
      end.to change { decorated_article.pinned? }.to(true)
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

    it "creates an audit log on update" do
      Audit::Subscribe.listen(:moderator)

      expect do
        patch admin_article_path(article.id), params: { article: { approved: true } }
      end.to change(AuditLog, :count).by(1)

      Audit::Subscribe.forget(:moderator)
    end
  end

  context "when unpinning an article" do
    before do
      sign_in super_admin
    end

    it "responds with :not_found with an invalid article id" do
      expect { delete unpin_admin_article_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "allows an admin to unpin an article", :aggregate_failures do
      PinnedArticle.set(article)

      delete unpin_admin_article_path(article.id)

      expect(PinnedArticle.exists?).to be(false)
      expect(response).to redirect_to(admin_article_path(article.id))
    end

    it "allows an admin to unpin an article via Ajax", :aggregate_failures do
      PinnedArticle.set(article)

      delete unpin_admin_article_path(article.id), xhr: true

      expect(PinnedArticle.exists?).to be(false)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include('data-controller="article"')
    end

    it "creates an audit log" do
      Audit::Subscribe.listen(:moderator)

      expect do
        delete unpin_admin_article_path(article.id)
      end.to change(AuditLog, :count).by(1)

      Audit::Subscribe.forget(:moderator)
    end
  end
end
