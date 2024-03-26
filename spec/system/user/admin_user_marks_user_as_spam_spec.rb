require "rails_helper"

RSpec.describe "Spam Toggling for User", type: :request do
  let!(:user) { create(:user) }
  let!(:admin) { create(:user, :admin) }
  let!(:non_admin) { create(:user) }
  let!(:spam_user) { create(:user, :spam) }

  describe "PUT /users/:id/spam" do
    context "when user exists" do
      before do
        sign_in admin
        put spam_user_path(user)
      end

      it "marks user as spam" do
        expect(response).to have_http_status(:no_content)
        expect(user.reload).to be_spam
      end
    end

    context "when user does not exist" do
      before { sign_in admin }

      it "returns a not found status" do
        put spam_user_path(id: -1)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      before { sign_in non_admin }

      it "prevents non-admins from marking a user as spam" do
        expect { put spam_user_path(user) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /users/:id/spam" do
    context "when user exists and is marked as spam" do
      before do
        sign_in admin
        delete spam_user_path(spam_user)
      end

      it "removes user from spam" do
        expect(response).to have_http_status(:no_content)
        expect(spam_user.reload).not_to be_spam
      end
    end

    context "when user does not exist" do
      before { sign_in admin }

      it "returns a not found status" do
        delete spam_user_path(id: -1) # Changed to a likely non-existent ID
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when unauthorized" do
      before { sign_in non_admin }

      it "prevents non-admins from removing a user from spam" do
        expect { delete spam_user_path(user) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
