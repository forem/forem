require "rails_helper"

RSpec.describe "ArticlesAdminUnpublish", type: :request do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
  end

  it "unpublishes an article" do
    expect(article.published).to be true
    patch "/articles/#{article.id}/admin_unpublish", params: {
      id: article.id,
      username: user.username,
      slug: article.slug
    }

    article.reload
    expect(article.published).to be false
  end

  it "removes the related notifications when unpublishing" do
    expect(article.published).to be true
    create(:notification, notifiable: article, action: "Published")
    expect do
      patch "/articles/#{article.id}/admin_unpublish", params: {
        id: article.id,
        username: user.username,
        slug: article.slug
      }
    end.to change(Notification, :count).by(-1)
  end
end
