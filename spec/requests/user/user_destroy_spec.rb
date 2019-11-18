require "rails_helper"

RSpec.describe "UserDestroy", type: :request do
  let(:user) { create(:user) }

  describe "DELETE /users/destroy" do
    context "when user has no articles or comments" do
      before do
        sign_in user
        delete "/users/destroy"
      end

      it "destroys the user" do
        expect(user.persisted?).to eq false
      end

      it "sends an email to the user" do
        expect(EmailMessage.last.to).to eq user.email
      end

      it "signs out the user" do
        expect(controller.current_user).to eq nil
      end

      it "redirects successfully to the home page" do
        expect(response).to redirect_to "/"
      end

      it "sets flash settings" do
        expect(flash[:global_notice]).to include("has been deleted")
      end
    end

    context "when users are not allowed to destroy" do
      let(:user_with_article) { create(:user, :with_article) }
      let(:user_with_comment) { create(:user, :with_only_comment) }
      let(:user_with_article_and_comment) { create(:user, :with_article_and_comment) }
      let(:users) { [user_with_article, user_with_comment, user_with_article_and_comment] }

      it "does not allow invalid users to delete their account" do
        users.each do |user|
          sign_in user
          delete "/users/destroy"
          expect(user.persisted?).to eq true
        end
      end

      it "redirects successfully to /settings/account" do
        users.each do |user|
          sign_in user
          delete "/users/destroy"
          expect(response).to redirect_to "/settings/account"
        end
      end

      it "shows the proper error message after redirecting" do
        users.each do |user|
          sign_in user
          delete "/users/destroy"
          expect(flash[:error]).to eq "An error occurred. Try requesting an account deletion below."
        end
      end
    end
  end

  describe "DELETE /users/full_delete" do
    before do
      sign_in user
    end

    it "schedules a user delete job" do
      expect do
        delete "/users/full_delete"
      end.to have_enqueued_job(Users::SelfDeleteJob).with(user.id)
    end

    it "signs out" do
      delete "/users/full_delete"
      expect(controller.current_user).to eq nil
    end

    it "redirects to root" do
      delete "/users/full_delete"
      expect(response).to redirect_to "/"
      expect(flash[:global_notice]).to include("Your account deletion is scheduled")
    end
  end

  describe "GET /users/request_destroy" do
    before do
      allow(NotifyMailer).to receive(:account_deletion_requested_email).and_call_original
      sign_in user
      get "/users/request_destroy"
    end

    it "sends an email" do
      expect(NotifyMailer).to have_received(:account_deletion_requested_email).with(user)
    end

    it "updates the destroy_token" do
      user.reload
      expect(user.destroy_token).to be_truthy
    end

    it "sets flash notice" do
      expect(flash[:settings_notice]).to include("You have requested account deletion")
    end
  end
end
