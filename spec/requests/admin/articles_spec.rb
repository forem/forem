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
        article.update_columns(second_user_id: second_user.id)
      end.to change(article, :second_user_id).from(nil).to(second_user.id)
    end

    it "allows an Admin to add multiple co-authors to an individual article" do
      article.update_columns(second_user_id: second_user.id, third_user_id: third_user.id)

      get request

      article.reload

      expect(article.second_user_id).to eq(second_user.id)
      expect(article.third_user_id).to eq(third_user.id)
    end
  end
end
