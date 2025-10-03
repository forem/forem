require "rails_helper"

describe Rack, ".attack", throttle: true, type: :request do
  before do
    allow(Rails).to receive(:cache) { ActiveSupport::Cache.lookup_store(:redis_cache_store) }
    allow(Honeycomb).to receive(:add_field)
    ENV["FASTLY_API_KEY"] = "12345"
  end

  after do
    ENV["FASTLY_API_KEY"] = nil
    Rails.cache.clear
  end

  describe "search_throttle" do
    it "throttles /search endpoints based on IP" do
      Timecop.freeze do
        allow(Search::Username).to receive(:search_documents).and_return({})

        valid_responses = Array.new(5).map do
          get "/search/usernames", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        throttled_response = get "/search/usernames", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        new_ip_response = get "/search/usernames", headers: { "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" }

        valid_responses.each { |r| expect(r).not_to eq(429) }
        expect(throttled_response).to eq(429)
        expect(new_ip_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(6).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").at_least(1).times
      end
    end
  end

  describe "api_throttle" do
    it "throttles api get endpoints based on IP" do
      Timecop.freeze do
        valid_responses = Array.new(3).map do
          get api_articles_path, headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        throttled_response = get api_articles_path, headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        new_ip_response = get api_articles_path, headers: { "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" }

        valid_responses.each { |r| expect(r).not_to eq(429) }
        expect(throttled_response).to eq(429)
        expect(new_ip_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(4).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").at_least(1).times
      end
    end

    it "doesn't throttle when API key provided belongs to admin" do
      admin_api_key = create(:api_secret, user: create(:user, :admin))

      Timecop.freeze do
        headers = { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8", "api-key" => admin_api_key.secret }
        valid_responses = Array.new(10).map do
          get api_articles_path, headers: headers
        end

        valid_responses.each { |r| expect(r).not_to eq(429) }
        # Admin users bypass throttling, so no Honeycomb calls expected
      end
    end
  end

  describe "api_write_throttle" do
    let(:api_secret) { create(:api_secret) }
    let(:another_api_secret) { create(:api_secret) }
    let(:headers) do
      { "api-key" => api_secret.secret, "content-type" => "application/json", "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
    end
    let(:dif_headers) do
      {
        "api-key" => another_api_secret.secret,
        "content-type" => "application/json",
        "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8"
      }
    end

    it "throttles api write endpoints based on IP and API key" do
      params = { article: { body_markdown: "", title: Faker::Book.title } }.to_json

      Timecop.freeze do
        valid_response = post api_articles_path, params: params, headers: headers
        throttled_response = post api_articles_path, params: params, headers: headers
        new_api_response = post api_articles_path, params: params, headers: dif_headers

        expect(valid_response).not_to eq(429)
        expect(throttled_response).to eq(429)
        expect(new_api_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(3).times
        expect(Honeycomb).to have_received(:add_field).with("user_api_key", api_secret.secret).exactly(2).times
        expect(Honeycomb).to have_received(:add_field).with("user_api_key", another_api_secret.secret)
      end
    end

    it "throttles api write endpoints based on IP if API key not present" do
      headers = { "content-type" => "application/json", "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
      dif_headers = { "content-type" => "application/json", "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" }
      params = { article: { body_markdown: "", title: Faker::Book.title } }.to_json

      Timecop.freeze do
        valid_response = post api_articles_path, params: params, headers: headers
        throttled_response = post api_articles_path, params: params, headers: headers
        new_api_response = post api_articles_path, params: params, headers: dif_headers

        expect(valid_response).not_to eq(429)
        expect(throttled_response).to eq(429)
        expect(new_api_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(2).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").at_least(1).times
      end
    end

    it "doesn't throttle api write endpoints when API key provided belongs to admin" do
      admin_api_key = create(:api_secret, user: create(:user, :admin))
      params = { article: { body_markdown: "", title: Faker::Book.title } }.to_json
      admin_headers = {
        "api-key" => admin_api_key.secret,
        "content-type" => "application/json",
        "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8"
      }

      Timecop.freeze do
        valid_responses = Array.new(10).map do
          post api_articles_path, params: params, headers: admin_headers
        end

        valid_responses.each { |r| expect(r).not_to eq(429) }
        # Admin users bypass throttling, so no Honeycomb calls expected
        expect(Honeycomb).to have_received(:add_field).with("user_api_key", admin_api_key.secret).exactly(10).times
      end
    end
  end

  describe "tag_throttle" do
    let(:user) { create(:user) }
    let(:headers) { { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" } }
    let(:dif_headers) { { "HTTP_FASTLY_CLIENT_IP" => "1.1.1.1" } }

    before do
      sign_in user
    end

    # rubocop:disable RSpec/AnyInstance, RSpec/ExampleLength
    it "no longer throttles tag pages (edge cached)", :aggregate_failures do
      allow_any_instance_of(Stories::TaggedArticlesController).to receive(:tagged_count).and_return(0)
      allow_any_instance_of(Stories::TaggedArticlesController).to receive(:stories_by_timeframe)
        .and_return(Article.none)
      allow(Articles::Feeds::Tag).to receive(:call).and_return(Article.none)
      tag_path = "/t/#{create(:tag).name}"

      get tag_path, headers: headers # warm up the slow endpoint

      Timecop.freeze do
        # Tag pages are now edge cached, so no throttling should occur
        valid_responses = Array.new(50).map do
          get tag_path, headers: headers
        end
        new_response = get tag_path, headers: dif_headers

        # All requests should succeed (no throttling for edge-cached content)
        valid_responses.each { |r| expect(r).not_to eq(429) }
        expect(new_response).not_to eq(429)
      end
    end
    # rubocop:enable RSpec/AnyInstance, RSpec/ExampleLength
  end

  describe "forgot_password_throttle" do
    it "throttles after 3 attempts" do
      params = { user: { email: "yo@email.com" } }
      admin_headers = { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }

      Timecop.freeze do
        3.times do
          post "/users/password", params: params, headers: admin_headers
          expect(response).to have_http_status(:found)
        end
        3.times do
          post "/users/password", params: params, headers: admin_headers
          expect(response).to have_http_status(:too_many_requests)
        end
      end
    end
  end

  describe "edge-cached page throttling removal" do
    it "confirms that edge-cached pages are no longer throttled" do
      # These pages are edge-cached globally, so Rack Attack rules were removed
      # to reduce Redis overhead since they rarely apply
      
      Timecop.freeze do
        # Homepage should not be throttled (edge cached)
        homepage_responses = Array.new(50).map do
          get "/", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        
        # Latest should not be throttled (edge cached)
        latest_responses = Array.new(50).map do
          get "/latest", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        
        # Article pages should not be throttled (edge cached)
        article = create(:article, published: true)
        article_responses = Array.new(50).map do
          get "/#{article.user.username}/#{article.slug}", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        
        # Tag pages should not be throttled (edge cached)
        tag = create(:tag)
        tag_responses = Array.new(50).map do
          get "/t/#{tag.name}", headers: { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" }
        end
        
        # All should succeed (no throttling for edge-cached content)
        homepage_responses.each { |r| expect(r).not_to eq(429) }
        latest_responses.each { |r| expect(r).not_to eq(429) }
        article_responses.each { |r| expect(r).not_to eq(429) }
        tag_responses.each { |r| expect(r).not_to eq(429) }
      end
    end
  end
end
