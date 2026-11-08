require "rails_helper"

RSpec.describe "Rack::Attack Magic Links Throttling" do
  include ActiveSupport::Testing::TimeHelpers

  let(:headers) { { "REMOTE_ADDR" => "5.6.7.8" } }

  before do
    freeze_time
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
    Rails.cache.clear
  end

  after do
    Rack::Attack.enabled = false
  end

  it "throttles POST /magic_links to 5 per minute per IP" do
    5.times do |i|
      post "/magic_links", params: { email: "user#{i}@example.com" }, headers: headers
      expect(response).not_to have_http_status(:too_many_requests)
    end

    post "/magic_links", params: { email: "user5@example.com" }, headers: headers
    expect(response).to have_http_status(:too_many_requests)
  end

  it "throttles POST /magic_links to 3 per 10 minutes per email across IPs and casing" do
    3.times do |i|
      post "/magic_links", params: { email: "target@example.com" }, headers: { "REMOTE_ADDR" => "1.1.1.#{i}" }
      expect(response).not_to have_http_status(:too_many_requests)
    end

    post "/magic_links", params: { email: " TARGET@example.com" }, headers: { "REMOTE_ADDR" => "1.1.1.9" }
    expect(response).to have_http_status(:too_many_requests)
  end

  it "throttles code guesses to 10 per minute per IP, including HEAD and locale paths" do
    5.times { |i| get "/magic_links/#{i}", headers: headers }
    4.times { |i| head "/magic_links/h#{i}", headers: headers }
    get "/locale/fr/magic_links/last", headers: headers
    expect(response).not_to have_http_status(:too_many_requests)

    get "/magic_links/over", headers: headers
    expect(response).to have_http_status(:too_many_requests)
  end

  it "does not count the /magic_links/new form as a code guess" do
    11.times { get "/magic_links/new", headers: headers }

    expect(response).to have_http_status(:ok)
  end
end
