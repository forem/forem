require "rails_helper"

RSpec.describe "Api::V1::OrganizationArticleAnalytics" do
  let(:organization) { create(:organization) }
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json", "api-key" => api_secret.secret } }
  let(:path) { "/api/organizations/#{organization.id}/article_analytics" }

  before { FeatureFlag.enable(:org_article_analytics, FeatureFlag::Actor[organization]) }

  after { FeatureFlag.remove(:org_article_analytics) }

  it "requires organization entitlement and revokes it when disabled" do
    create(:organization_membership, organization: organization, user: user)
    FeatureFlag.remove(:org_article_analytics)
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
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

  it "rejects unauthenticated users, outsiders, and suspended members even when globally enabled" do
    get path, headers: headers.except("api-key")
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["Surrogate-Control"]).to eq("no-store")

    FeatureFlag.enable(:org_article_analytics)
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)

    create(:organization_membership, organization: organization, user: user)
    user.add_role(:suspended)
    get path, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 404 with no-store headers when the organization does not exist" do
    get "/api/organizations/0/article_analytics", headers: headers
    expect(response).to have_http_status(:not_found)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["Surrogate-Control"]).to eq("no-store")
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
    create(:article, organization: organization, published: true, published_at: 1.day.from_now)
    create(:article, organization: organization, subforem: create(:subforem))
    create(:article, user: user)
    create(:article, title: organization.name)

    get path, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("id")).to eq([article.id])
    expect(response.parsed_body.first).to include("page_views_count" => 123, "public_reactions_count" => 7,
                                                  "comments_count" => 2, "url" => URL.article(article))
    expect(response.parsed_body.first.keys).to match_array(
      %w[id title path url user_id organization_id published_at updated_at
         page_views_count public_reactions_count comments_count],
    )
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["Surrogate-Control"]).to eq("no-store")
  end

  it "builds article URLs using the article subforem domain and organization custom domain", :aggregate_failures do
    create(:subforem, domain: "default.test")
    secondary_subforem = create(:subforem, domain: "secondary.test")
    create(:organization_membership, organization: organization, user: user)
    article = create(:article, organization: organization, subforem: secondary_subforem)
    article.update_column(:page_views_count, nil)

    get path, headers: headers.merge("Host" => secondary_subforem.domain)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.first["url"]).to eq("http://secondary.test#{article.path}")
    expect(response.parsed_body.first["page_views_count"]).to eq(0)

    organization.update!(custom_domain: "blog.acme.test")
    FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[organization])

    get path, headers: headers.merge("Host" => secondary_subforem.domain)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.first["url"]).to eq("http://blog.acme.test/#{article.slug}")
  ensure
    FeatureFlag.remove(:org_custom_domain)
  end

  it "supports session authentication and bounded stable pagination", :aggregate_failures do
    create(:organization_membership, organization: organization, user: user, type_of_user: "admin")
    first = create(:article, organization: organization)
    second = create(:article, organization: organization)
    sign_in user

    get path, params: { per_page: 1 }, headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([first.id])
    get path, params: { per_page: 1, page: 2 }, headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([second.id])

    get path, params: { per_page: "", page: -2 }, headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([first.id, second.id])

    get path, params: { per_page: 1, page: 1001 }, headers: headers.except("api-key")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([])
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
