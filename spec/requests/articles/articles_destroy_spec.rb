require "rails_helper"

RSpec.describe "ArticlesDestroy" do
  let(:user) { create(:user, :org_admin) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  context "when DELETE /articles/:slug" do
    it "destroyed an article" do
      delete "/articles/#{article.id}"
      destroyed_article = Article.find_by(id: article.id)
      expect(destroyed_article).to be_nil
    end

    it "schedules a RemoveAllWorker if there are comments" do
      create(:comment, commentable: article, user: user)
      sidekiq_assert_enqueued_with(job: Notifications::RemoveAllWorker) do
        delete "/articles/#{article.id}"
      end
    end

    it "removes all previous published notifications" do
      create(:notification, notifiable: article, action: "Published", user: user)
      expect do
        delete "/articles/#{article.id}"
      end.to change(Notification, :count).by(-1)
    end

    it "doesn't destroy another person's article" do
      article2 = create(:article, user_id: create(:user).id)
      expect do
        delete "/articles/#{article2.id}"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "when GET /delete_confirm" do
    context "without an article" do
      before { sign_in user }

      it "renders not_found" do
        article = create(:article, user: user)
        expect do
          get "#{article.path}_1/delete_confirm"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with an article the current user wrote" do
      before { sign_in user }

      it "renders success" do
        article = create(:article, user: user)
        get "#{article.path}/delete_confirm"
        expect(response).to be_successful
      end
    end

    context "when an admin attempts to delete an article" do
      let(:admin) { create(:user, :admin) }

      before { sign_in admin }

      it "renders success" do
        article = create(:article, user: user)
        get "#{article.path}/delete_confirm"
        expect(response).to be_successful
      end
    end

    context "when another user attempts to delete someone's article" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "raises a policy error" do
        article = create(:article, user: user)
        expect do
          get "#{article.path}/delete_confirm"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
