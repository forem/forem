require "rails_helper"

# Regression spec for https://github.com/forem/forem/issues/12444
RSpec.describe "", type: :request do
  it "does not infinitely redirect", :aggregate_failures do
    organization = create(:organization, username: "test")
    organization.update(username: "not_test")
    organization.update(username: "test")
    article = create(:article, organization: organization)
    user = article.user

    get "/#{user.username}/#{article.slug}"

    expect(response).to redirect_to(article.path)
    follow_redirect!
    expect(response).to have_http_status(:ok)
  end
end
