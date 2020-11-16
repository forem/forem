require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/articles", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get "/admin/articles" }
  end

  context "when updating an Article via /admin/articles" do
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
        patch "/admin/articles/#{article.id}", params: { article: { approved: true } }
      end.to change { article.reload.approved }.to(true)
    end

    it "allows an Admin to mark an article as featured" do
      expect do
        patch "/admin/articles/#{article.id}", params: { article: { featured: true } }
      end.to change { article.reload.featured }.to(true)
    end
  end
end
