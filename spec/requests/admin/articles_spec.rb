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

    before { sign_in super_admin }

    it "allows an Admin to add a co-author to an individual article" do
      get request

      expect do
        article.update_columns(co_author_ids: [1])
      end.to change(article, :co_author_ids).from([]).to([1])
    end

    it "allows an Admin to add co-authors to an individual article" do
      article.update_columns(co_author_ids: [2, 3])
      get request
      expect(article.co_author_ids).to eq([2, 3])
    end
  end
end
