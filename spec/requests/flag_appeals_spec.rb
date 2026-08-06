require "rails_helper"

RSpec.describe "FlagAppeals", type: :request do
  let(:user) { create(:user) }

  describe "GET /appeal" do
    context "when user is not authenticated" do
      it "redirects to sign in / magic link" do
        get appeal_path
        expect(response).to redirect_to(new_magic_link_path)
      end
    end

    context "when user is authenticated" do
      before { sign_in user }

      it "renders the new appeal page successfully" do
        get appeal_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Submit a Moderation Appeal")
      end
    end
  end

  describe "POST /appeal" do
    before { sign_in user }

    context "with valid parameters" do
      it "creates a FlagAppeal and redirects to appeal success page" do
        expect do
          post appeal_path, params: {
            flag_appeal: {
              reason: "My post was not spam, it was technical documentation.",
              appealable_type: "User",
              appealable_id: user.id
            }
          }
        end.to change(FlagAppeal, :count).by(1)

        appeal = FlagAppeal.last
        expect(response).to redirect_to(appeal_success_path(id: appeal.id))
        expect(flash[:notice]).to be_present
      end

      it "sanitizes unauthorized appealable_id to current_user to prevent IDOR" do
        other_user_article = create(:article)
        post appeal_path, params: {
          flag_appeal: {
            reason: "Attempting to appeal another user's article",
            appealable_type: "Article",
            appealable_id: other_user_article.id
          }
        }

        appeal = FlagAppeal.last
        expect(appeal.appealable_type).to eq("User")
        expect(appeal.appealable_id).to eq(user.id)
      end
    end

    context "with invalid parameters" do
      it "renders new with unprocessable_entity status" do
        post appeal_path, params: {
          flag_appeal: {
            reason: "",
            appealable_type: "User",
            appealable_id: user.id
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /appeal/success" do
    let!(:appeal) { create(:flag_appeal, user: user) }

    before { sign_in user }

    it "renders post-submission confirmation landing page" do
      get appeal_success_path(id: appeal.id)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Thank you for your appeal submission")
    end

    it "redirects to root when accessing another user's appeal" do
      other_user_appeal = create(:flag_appeal)
      get appeal_success_path(id: other_user_appeal.id)
      expect(response).to redirect_to(root_path)
    end
  end
end
