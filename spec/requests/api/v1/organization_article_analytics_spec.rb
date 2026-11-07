require "rails_helper"

RSpec.describe "Api::V1::OrganizationArticleAnalytics" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json", "api-key" => api_secret.secret } }
  let(:path) { "/api/organizations/#{organization.id}/article_analytics" }

  before { FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[organization]) }

  it "requires organization entitlement and revokes it when disabled" do
    create(:organization_membership, organization: organization, user: user)
    FeatureFlag.disable(:org_article_analytics, FeatureFlag::Actor[organization])
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
    FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[create(:organization)])
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
    FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[organization])
    get path, headers: headers
    expect(response).to have_http_status(:ok)
    FeatureFlag.disable(:org_article_analytics, FeatureFlag::Actor[organization])
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects unauthenticated users and outsiders" do
    get path, headers: headers.except("api-key")
    expect(response).to have_http_status(:unauthorized)
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "does not authorize pending or guest memberships" do
    membership = create(:organization_membership, organization: organization, user: user, type_of_user: "pending")
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
    membership.update!(type_of_user: "guest")
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "exports organization posts with lifetime counters and excludes other posts", :aggregate_failures do
    create(:subforem, domain: "forem.test")
    create(:organization_membership, organization: organization, user: user)
    article = create(:article, organization: organization)
    article.update_columns(page_views_count: 123, public_reactions_count: 7, comments_count: 2)
    create(:article, organization: organization, published: false)
    create(:article, organization: organization, subforem: create(:subforem))
    create(:article, user: user)
    create(:article, title: organization.name)

    get path, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("id")).to eq([article.id])
    expect(response.parsed_body.first).to include("page_views_count" => 123, "public_reactions_count" => 7,
                                                  "comments_count" => 2, "url" => URL.url(article.path))
    expect(response.parsed_body.first.keys).not_to include("body_markdown", "email", "cached_user")
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["Surrogate-Control"]).to eq("no-store")
  end

  it "supports session authentication and stable pagination" do
    create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
    first = create(:article, organization: organization)
    second = create(:article, organization: organization)
    sign_in user

    get path, params: { per_page: 1 }, headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([first.id])
    get path, params: { per_page: 1, page: 2 }, headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([second.id])
  end

  it "revokes access after membership removal" do
    membership = create(:organization_membership, organization: organization, user: user)
    get path, headers: headers
    expect(response).to have_http_status(:ok)
    membership.destroy!
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end
end
