require "rails_helper"

RSpec.describe "Api::V1::RelatedArticles" do
  let(:api_secret) { create(:api_secret) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json", "api-key" => api_secret.secret } }
  let(:organization) { create(:organization) }

  before do
    create(:organization_membership, organization: organization, user: api_secret.user)
    FeatureFlag.enable(:org_related_articles, FeatureFlag::Actor[organization])
  end

  it "requires authentication" do
    get "/api/related_articles", params: { organization_id: organization.id, q: "database" },
                                 headers: headers.except("api-key")
    expect(response).to have_http_status(:unauthorized)
  end

  it "finds alternative technology names without exposing private counters or draft content", :aggregate_failures do
    first = create(:article, title: "Build with TimescaleDB")
    second = create(:article, title: "Tiger Data tutorial")
    create(:article, title: "Tiger Data draft", published: false)
    create(:article, title: "An unrelated tutorial")

    get "/api/related_articles", params: { organization_id: organization.id, q: "TimescaleDB,Tiger Data" },
                                 headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("id")).to eq([second.id, first.id])
    expect(response.parsed_body.first.keys).not_to include("page_views_count", "body_markdown", "email")
    expect(response.headers["Cache-Control"]).to eq("no-store")
    expect(response.headers["Surrogate-Control"]).to eq("no-store")
  end

  it "uses publication dates and stable pagination rather than popularity" do
    first = create(:article, title: "TimescaleDB first")
    second = create(:article, title: "TimescaleDB second")
    first.update_columns(published_at: 2.days.ago, hotness_score: 10_000)
    second.update_columns(published_at: 1.day.ago, hotness_score: 0)

    get "/api/related_articles", params: { organization_id: organization.id, q: "TimescaleDB", per_page: 1 },
                                 headers: headers
    expect(response.parsed_body.pluck("id")).to eq([second.id])
    get "/api/related_articles",
        params: { organization_id: organization.id, q: "TimescaleDB", per_page: 1, page: 2 }, headers: headers
    expect(response.parsed_body.pluck("id")).to eq([first.id])
  end

  it "restricts results to the requested date interval" do
    old = create(:article, title: "TimescaleDB old")
    old.update_columns(published_at: 10.days.ago)
    current = create(:article, title: "TimescaleDB current")

    get "/api/related_articles",
        params: { organization_id: organization.id, q: "TimescaleDB", start: Date.current.iso8601,
                  end: Date.current.iso8601 }, headers: headers

    expect(response.parsed_body.pluck("id")).to eq([current.id])
  end

  it "rejects invalid or unbounded input" do
    [{}, { q: "!!!" }, { q: ["database"] }, { q: "a,b,c,d,e,f" }, { q: "x" * 501 },
     { q: "database", page: "abc" }, { q: "database", per_page: "xyz" },
     { q: "database", start: "2026-02-30" }, { q: "database", start: "2026-11-04", end: "2026-11-03" }].each do |params|
      get "/api/related_articles", params: params.merge(organization_id: organization.id), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it "returns 404 when the requested organization does not exist" do
    get "/api/related_articles", params: { organization_id: 0, q: "database" }, headers: headers
    expect(response).to have_http_status(:not_found)
  end

  it "requires organization entitlement, active membership, and explicit organization context" do
    allow(Ai::Embedding).to receive(:new).and_call_original
    get "/api/related_articles", params: { q: "database", mode: "hybrid" }, headers: headers
    expect(response).to have_http_status(:unprocessable_entity)
    params = { organization_id: organization.id, q: "database", mode: "hybrid" }
    FeatureFlag.remove(:org_related_articles)
    get "/api/related_articles", params: params, headers: headers
    expect(response).to have_http_status(:unauthorized)
    FeatureFlag.disable(:org_related_articles, FeatureFlag::Actor[organization])
    get "/api/related_articles", params: params, headers: headers
    expect(response).to have_http_status(:unauthorized)
    other = create(:organization)
    FeatureFlag.enable(:org_related_articles, FeatureFlag::Actor[other])
    get "/api/related_articles", params: params.merge(organization_id: other.id), headers: headers
    expect(response).to have_http_status(:unauthorized)
    FeatureFlag.enable(:org_related_articles, FeatureFlag::Actor[organization])
    membership = api_secret.user.organization_memberships.find_by!(organization: organization)
    %w[pending guest].each do |role|
      membership.update!(type_of_user: role)
      get "/api/related_articles", params: params, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
    membership.destroy!
    get "/api/related_articles", params: params, headers: headers
    expect(response).to have_http_status(:unauthorized)
    expect(Ai::Embedding).not_to have_received(:new)
  end

  it "combines lexical and semantic matches while enforcing public scope and date filters", :aggregate_failures do
    create(:subforem, domain: "forem.test")
    query_vector = [1.0] + Array.new(767, 0.0)
    embedding = instance_double(Ai::Embedding, call: query_vector)
    allow(Ai::Embedding).to receive(:new).and_return(embedding)
    keyword = create(:article, title: "Database lexical", score: 100)
    keyword.update_column(:semantic_embedding, nil)
    semantic = create(:article, title: "Vector tutorial", score: 100)
    semantic.update_column(:semantic_embedding, query_vector)
    both = create(:article, title: "Database vectors", score: 100)
    both.update_column(:semantic_embedding, query_vector)
    hidden = create(:article, title: "Hidden vectors", published: false, score: 100)
    other = create(:article, title: "Elsewhere vectors", subforem: create(:subforem), score: 100)
    old = create(:article, title: "Old vectors", score: 100)
    old.update_column(:published_at, 10.days.ago)
    low = create(:article, title: "Low vectors", score: -100)
    [hidden, other, old, low].each { |article| article.update_column(:semantic_embedding, query_vector) }

    get "/api/related_articles", params: { organization_id: organization.id, q: "database", mode: "hybrid",
                                           start: Date.current.iso8601 }, headers: headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck("id")).to contain_exactly(keyword.id, semantic.id, both.id)
    expect(response.parsed_body.first["id"]).to eq(both.id)
    expect(response.parsed_body.detect { |a| a["id"] == semantic.id }["discovery_match"]).to eq(["semantic"])
    expect(response.parsed_body.detect { |a| a["id"] == both.id }["discovery_match"]).to eq(%w[keyword semantic])
    expect(response.headers["X-Discovery-Mode"]).to eq("hybrid")
    expect(response.headers["X-Discovery-Candidate-Limit"]).to eq("200")
    expect(response.headers["X-Discovery-Exhaustive"]).to eq("false")
    expect(response.parsed_body.first.keys).not_to include("semantic_embedding", "page_views_count", "body_markdown")
  end

  it "falls back visibly to keyword results on provider failure or malformed vectors" do
    article = create(:article, title: "Database fallback")
    embedding = instance_double(Ai::Embedding)
    allow(Ai::Embedding).to receive(:new).and_return(embedding)
    allow(embedding).to receive(:call).and_raise(Timeout::Error)
    params = { organization_id: organization.id, q: "database", mode: "hybrid" }
    get "/api/related_articles", params: params, headers: headers
    expect(response.parsed_body.pluck("id")).to eq([article.id])
    expect(response.headers["X-Discovery-Mode"]).to eq("keyword")
    allow(embedding).to receive(:call).and_return([Float::NAN])
    get "/api/related_articles", params: params, headers: headers
    expect(response.parsed_body.pluck("id")).to eq([article.id])
    expect(response.headers["X-Discovery-Mode"]).to eq("keyword")
  end

  it "supports sessions, deterministic hybrid pagination, and cached query embeddings" do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    embedding = instance_double(Ai::Embedding)
    allow(Ai::Embedding).to receive(:new).and_return(embedding)
    allow(embedding).to receive(:call).and_return([1.0] + Array.new(767, 0.0))
    first = create(:article, title: "Database first")
    second = create(:article, title: "Database second")
    [first, second].each { |article| article.update_column(:semantic_embedding, nil) }
    sign_in api_secret.user
    params = { organization_id: organization.id, q: "database", mode: "hybrid", per_page: 1 }
    get "/api/related_articles", params: params, headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([second.id])
    get "/api/related_articles", params: params.merge(page: 2), headers: headers.except("api-key")
    expect(response.parsed_body.pluck("id")).to eq([first.id])
    expect(embedding).to have_received(:call).once
    get "/api/related_articles", params: params.merge(mode: "semantic"), headers: headers.except("api-key")
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "bounds each hybrid candidate source and excludes distant vectors" do
    stub_const("Articles::RelatedDiscovery::CANDIDATES_PER_SOURCE", 1)
    vector = [1.0] + Array.new(767, 0.0)
    embedding = instance_double(Ai::Embedding, call: vector)
    allow(Ai::Embedding).to receive(:new).and_return(embedding)
    ignored = create(:article, title: "Database older", score: 100)
    latest = create(:article, title: "Database latest", score: 100)
    semantic = create(:article, title: "Related vector", score: 100)
    far = create(:article, title: "Distant vector", score: 100)
    [ignored, latest].each { |a| a.update_column(:semantic_embedding, nil) }
    semantic.update_column(:semantic_embedding, vector)
    far.update_column(:semantic_embedding, [-1.0] + Array.new(767, 0.0))
    get "/api/related_articles",
        params: { organization_id: organization.id, q: "database", mode: "hybrid" }, headers: headers
    expect(response.parsed_body.pluck("id")).to contain_exactly(latest.id, semantic.id)
    expect(response.headers["X-Discovery-Candidate-Limit"]).to eq("2")
    expect(Article.connection.select_value("SHOW hnsw.iterative_scan")).to eq("off")
    expect(Article.connection.select_value("SHOW hnsw.ef_search")).to eq("40")
  end
end
