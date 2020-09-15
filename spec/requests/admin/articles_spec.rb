require "rails_helper"
require "requests/shared_examples/internal_policy_dependant_request"

RSpec.describe "/admin/articles", type: :request do
  it_behaves_like "an InternalPolicy dependant request", Article do
    let(:request) { get "/admin/articles" }
  end

  context "when updating an Article via /admin/articles" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:article) { create(:article) }

    before { sign_in super_admin }

    it "allows an Admin to add a co-author to an individual article" do
      get request
      expect do
        article.update_columns(second_user_id: 1)
      end.to change(article, :second_user_id).from(nil).to(1)
    end

    it "allows an Admin to add co-authora to an individual article" do
      article.update_columns(second_user_id: 2, third_user_id: 3)
      get request
      expect(article.second_user_id).to eq(2)
      expect(article.third_user_id).to eq(3)
    end
  end
end
