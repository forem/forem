require "rails_helper"

RSpec.describe Moderator::DeleteUser, type: :service do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :super_admin) }

  describe "delete_user" do
    it "deletes user" do
      described_class.call_deletion(user: user, admin: admin, user_params: {})
      expect(User.find_by(id: user.id)).to be_nil
    end

    it "deletes user's follows" do
      create(:follow, follower: user)
      create(:follow, followable: user)

      expect do
        described_class.call_deletion(user: user, admin: admin, user_params: {})
      end.to change(Follow, :count).by(-2)
    end

    it "deletes user's articles" do
      article = create(:article, user: user)
      described_class.call_deletion(user: user, admin: admin, user_params: {})
      expect(Article.find_by(id: article.id)).to be_nil
    end
  end
end
