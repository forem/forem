require "rails_helper"

RSpec.describe "ArticlesAdminFeature" do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
  end

  it "features an article" do
    expect(article.featured).to be false
    patch "/articles/#{article.id}/admin_featured_toggle", params: {
      id: article.id,
      article: { featured: 1 }
    }

    article.reload
    expect(article.featured).to be true
  end

  it "unfeatures an article" do
    article.update_column(:featured, true)
    expect(article.featured).to be true
    patch "/articles/#{article.id}/admin_featured_toggle", params: {
      id: article.id,
      article: { featured: 0 }
    }

    article.reload
    expect(article.featured).to be false
  end
end
