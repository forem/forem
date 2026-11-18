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

  it "omits the daily series when start and end are not given" do
    create(:organization_membership, organization: organization, user: user)
    create(:article, organization: organization)

    get path, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.first).not_to have_key("daily")
  end

  it "adds a zero-filled daily series from article activities", :aggregate_failures do
    create(:organization_membership, organization: organization, user: user)
    article = create(:article, organization: organization)
    inactive_article = create(:article, organization: organization)
    ArticleActivity.create!(
      article: article,
      daily_page_views: {
        "2026-02-28" => { "total" => 99, "sum_read_seconds" => 0, "logged_in_count" => 0 },
        "2026-03-01" => { "total" => 12, "sum_read_seconds" => 30, "logged_in_count" => 2 },
        "2026-03-03" => { "total" => 5, "sum_read_seconds" => 0, "logged_in_count" => 0 }
      },
      daily_reactions: {
        "2026-03-01" => { "total" => 4, "like" => 2, "readinglist" => 1, "fire" => 1, "reactor_ids" => [1, 2, 3] }
      },
      daily_comments: { "2026-03-03" => 2, "2026-03-04" => 7 },
    )

    activity_queries = 0
    callback = lambda do |*, payload|
      activity_queries += 1 if payload[:sql].include?('"article_activities"')
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get path, params: { start: "2026-03-01", end: "2026-03-03" }, headers: headers
    end

    expect(response).to have_http_status(:ok)
    expect(activity_queries).to eq(1)
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["Surrogate-Control"]).to eq("no-store")
    body = response.parsed_body.index_by { |row| row["id"] }
    zero_reactions = { "total" => 0, "like" => 0, "readinglist" => 0, "unicorn" => 0,
                       "exploding_head" => 0, "raised_hands" => 0, "fire" => 0 }
    expect(body[article.id]["daily"]).to eq(
      [
        { "date" => "2026-03-01", "page_views" => 12, "comments" => 0,
          "reactions" => zero_reactions.merge("total" => 4, "like" => 2, "readinglist" => 1, "fire" => 1) },
        { "date" => "2026-03-02", "page_views" => 0, "comments" => 0, "reactions" => zero_reactions },
        { "date" => "2026-03-03", "page_views" => 5, "comments" => 2, "reactions" => zero_reactions },
      ],
    )
    expect(body[inactive_article.id]["daily"]).to eq(
      %w[2026-03-01 2026-03-02 2026-03-03].map do |date|
        { "date" => date, "page_views" => 0, "comments" => 0, "reactions" => zero_reactions }
      end,
    )
  end

  it "accepts a range of up to 90 days" do
    create(:organization_membership, organization: organization, user: user)
    create(:article, organization: organization)

    get path, params: { start: "2026-01-01", end: "2026-03-31" }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.first["daily"].pluck("date").values_at(0, -1)).to eq(%w[2026-01-01 2026-03-31])
    expect(response.parsed_body.first["daily"].size).to eq(90)
  end

  it "rejects invalid date ranges", :aggregate_failures do
    create(:organization_membership, organization: organization, user: user)
    invalid_format = I18n.t("api.v0.analytics_controller.invalid_date_format")
    {
      { start: "2026-03-01" } => "Date parameters 'start' and 'end' must be provided together",
      { end: "2026-03-01" } => "Date parameters 'start' and 'end' must be provided together",
      { start: "" } => "Date parameters 'start' and 'end' must be provided together",
      { start: "", end: "" } => invalid_format,
      { start: " ", end: " " } => invalid_format,
      { start: "2026-3-1", end: "2026-03-02" } => invalid_format,
      { start: "2026-03-01", end: "2026-02-30" } => invalid_format,
      { start: "yesterday", end: "today" } => invalid_format,
      { start: "2026-03-02", end: "2026-03-01" } => "Date parameter 'end' must not be before 'start'",
      { start: "2026-01-01", end: "2026-04-01" } => "Date range must not exceed 90 days"
    }.each do |params, message|
      get path, params: params, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq("error" => message, "status" => 422)
      expect(response.headers["Cache-Control"]).to eq("no-store")
    end
  end

  it "denies outsiders before validating the date range" do
    get path, params: { start: "2026-03-01", end: "2026-03-03" }, headers: headers
    expect(response).to have_http_status(:unauthorized)
    get path, params: { start: "2026-03-01" }, headers: headers
    expect(response).to have_http_status(:unauthorized)
  end
end
