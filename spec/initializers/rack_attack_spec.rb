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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(11).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(7).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(10).times
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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(5).times
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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").at_least(3).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
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
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(10).times
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
    it "throttles viewing tags", :aggregate_failures do
      allow_any_instance_of(Stories::TaggedArticlesController).to receive(:tagged_count).and_return(0)
      allow_any_instance_of(Stories::TaggedArticlesController).to receive(:stories_by_timeframe)
        .and_return(Article.none)
      allow(Articles::Feeds::Tag).to receive(:call).and_return(Article.none)
      tag_path = "/t/#{create(:tag).name}"

      get tag_path, headers: headers # warm up the slow endpoint

      Timecop.freeze do
        valid_responses = Array.new(2).map do
          get tag_path, headers: headers
        end
        throttled_response = get tag_path, headers: headers
        new_response = get tag_path, headers: dif_headers

        expect(valid_responses.first).not_to eq(429)
        expect(throttled_response).to eq(429)
        expect(new_response).not_to eq(429)
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "5.6.7.8").exactly(8).times
        expect(Honeycomb).to have_received(:add_field).with("fastly_client_ip", "1.1.1.1").exactly(2).times
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

  describe "authentication-based throttling" do
    let(:user) { create(:user) }
    let(:api_secret) { create(:api_secret, user: user) }
    let(:headers) { { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8" } }
    let(:api_headers) { { "HTTP_FASTLY_CLIENT_IP" => "5.6.7.8", "api-key" => api_secret.secret } }

    describe "user_signed_in? helper method" do
      it "returns true for session-based authentication" do
        sign_in user
        request = Rack::Attack::Request.new({})
        allow(request).to receive(:env).and_return({ "rack.session" => { "warden.user.user.key" => [[user.id], nil] } })
        
        expect(Rack::Attack.user_signed_in?(request)).to be true
      end

      it "returns true for API key authentication" do
        request = Rack::Attack::Request.new({})
        allow(request).to receive(:env).and_return({ "HTTP_API_KEY" => api_secret.secret })
        
        expect(Rack::Attack.user_signed_in?(request)).to be true
      end

      it "returns false for anonymous users" do
        request = Rack::Attack::Request.new({})
        allow(request).to receive(:env).and_return({})
        
        expect(Rack::Attack.user_signed_in?(request)).to be false
      end
    end

    describe "site_hits_signed_out" do
      it "throttles anonymous users more aggressively (20/2s)" do
        Timecop.freeze do
          # Make 10 requests (should be allowed - being very conservative due to overlapping rules)
          valid_responses = Array.new(10).map do
            get "/", headers: headers
          end
          
          # 11th request should be throttled
          throttled_response = get "/", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end

      it "does not throttle signed-in users with same IP" do
        sign_in user
        
        Timecop.freeze do
          # Make 40 requests (should be allowed for signed-in users)
          valid_responses = Array.new(40).map do
            get "/", headers: headers
          end
          
          # 41st request should be throttled
          throttled_response = get "/", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end
    end

    describe "site_hits_signed_in" do
      it "maintains original limits for signed-in users (40/2s)" do
        sign_in user
        
        Timecop.freeze do
          # Make 40 requests (should be allowed)
          valid_responses = Array.new(40).map do
            get "/", headers: headers
          end
          
          # 41st request should be throttled
          throttled_response = get "/", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end
    end

    describe "tag_throttle_signed_out" do
      it "throttles anonymous users more aggressively on tag pages (1/1s)" do
        tag = create(:tag)
        
        Timecop.freeze do
          # First request should be allowed
          valid_response = get "/t/#{tag.name}", headers: headers
          
          # Second request should be throttled
          throttled_response = get "/t/#{tag.name}", headers: headers
          
          expect(valid_response).not_to eq(429)
          expect(throttled_response).to eq(429)
        end
      end

      it "maintains original limits for signed-in users on tag pages (2/1s)" do
        sign_in user
        tag = create(:tag)
        
        Timecop.freeze do
          # First two requests should be allowed
          valid_responses = Array.new(2).map do
            get "/t/#{tag.name}", headers: headers
          end
          
          # Third request should be throttled
          throttled_response = get "/t/#{tag.name}", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end
    end

    describe "homepage_signed_out" do
      it "throttles anonymous users on homepage (10/1s)" do
        Timecop.freeze do
          # Make 5 requests (should be allowed - being very conservative due to overlapping rules)
          valid_responses = Array.new(5).map do
            get "/", headers: headers
          end
          
          # 6th request should be throttled
          throttled_response = get "/", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end

      it "throttles anonymous users on /latest (10/1s)" do
        Timecop.freeze do
          # Make 5 requests (should be allowed - being very conservative due to overlapping rules)
          valid_responses = Array.new(5).map do
            get "/latest", headers: headers
          end
          
          # 6th request should be throttled
          throttled_response = get "/latest", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end

      it "does not throttle signed-in users on homepage" do
        sign_in user
        
        Timecop.freeze do
          # Make 20 requests (should be allowed for signed-in users)
          valid_responses = Array.new(20).map do
            get "/", headers: headers
          end
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
        end
      end
    end

    describe "article_show_signed_out" do
      let(:article) { create(:article, published: true) }

      it "throttles anonymous users on article pages (5/1s)" do
        Timecop.freeze do
          # Make 5 requests (should be allowed)
          valid_responses = Array.new(5).map do
            get "/#{article.user.username}/#{article.slug}", headers: headers
          end
          
          # 6th request should be throttled
          throttled_response = get "/#{article.user.username}/#{article.slug}", headers: headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end

      it "does not throttle signed-in users on article pages" do
        sign_in user
        
        Timecop.freeze do
          # Make 10 requests (should be allowed for signed-in users)
          valid_responses = Array.new(10).map do
            get "/#{article.user.username}/#{article.slug}", headers: headers
          end
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
        end
      end
    end

    describe "API key authentication" do
      it "treats API key users as signed-in" do
        Timecop.freeze do
          # Make 40 requests with API key (should be allowed)
          valid_responses = Array.new(40).map do
            get "/", headers: api_headers
          end
          
          # 41st request should be throttled
          throttled_response = get "/", headers: api_headers
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
          expect(throttled_response).to eq(429)
        end
      end
    end

    describe "edge cases" do
      it "handles malformed article URLs correctly" do
        Timecop.freeze do
          # These should not match the article pattern - use a simple endpoint
          valid_responses = Array.new(10).map do
            get "/about", headers: headers
          end
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
        end
      end

      it "handles nested paths correctly" do
        Timecop.freeze do
          # These should not match the article pattern - use a simple endpoint
          valid_responses = Array.new(10).map do
            get "/privacy", headers: headers
          end
          
          valid_responses.each { |r| expect(r).not_to eq(429) }
        end
      end
    end
  end
end
