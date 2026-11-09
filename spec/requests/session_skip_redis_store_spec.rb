require "rails_helper"

RSpec.describe "RedisStore session loading with session_options[:skip]" do
  let(:user) { create(:user, :trusted) }
  let(:other_user) { create(:user) }
  let(:article) { create(:article, user: other_user) }
  let(:billboard) { create(:billboard, name: "test-bb", approved: true, published: true) }

  # Establishes a real session in ActionDispatch::Session::RedisStore, then clears
  # Warden's test-only `on_request` hook and `remember_user_token` cookie so subsequent
  # requests must load the unloaded session directly from RedisStore just like production.
  def establish_lazy_redis_session(target_user)
    sign_in target_user
    get "/async_info/base_data", headers: { "Accept" => "application/json" }
    csrf_token = response.parsed_body["token"]
    Warden::Manager._on_request.clear
    cookies.delete("remember_user_token")
    csrf_token
  end

  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = previous_store
  end

  it "authenticates GET /notifications/counts (plain and detailed) from an unloaded Redis session" do
    follow_instance = other_user.follow(user)
    Notification.send_new_follower_notification_without_delay(follow_instance)
    establish_lazy_redis_session(user)

    get "/notifications/counts"
    expect(response.body).to eq("1")
    expect(request.session_options[:skip]).to be(true)

    get "/notifications/counts", params: { mode: "detailed" }
    expect(response.parsed_body["count"]).to eq(1)
    expect(request.session_options[:skip]).to be(true)
  end

  it "authenticates POST /feed_events via MetalTelemetryFastPath from an unloaded Redis session" do
    establish_lazy_redis_session(user)
    event_params = {
      article_id: article.id,
      article_position: 1,
      category: :click,
      context_type: FeedEvent::CONTEXT_TYPE_HOME
    }

    expect do
      post "/feed_events", params: { feed_events: [event_params] }
    end.to change(FeedEvent, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(FeedEvent.last.user_id).to eq(user.id)
  end

  it "authenticates and verifies CSRF on ApplicationMetalController when MetalTelemetryFastPath defers" do
    csrf_token = establish_lazy_redis_session(user)
    event_params = {
      article_id: article.id,
      article_position: 2,
      category: :click,
      context_type: FeedEvent::CONTEXT_TYPE_HOME
    }

    # Force MetalTelemetryFastPath#verify_csrf! to defer before touching env["rack.session"],
    # then let FeedEventsController < ApplicationMetalController load session[:_csrf_token]
    # and session["warden.user.user.key"] from the unloaded Redis session.
    allow(FeedEventsController).to receive(:allow_forgery_protection).and_return(true)
    allow(FeedEventsController).to receive(:per_form_csrf_tokens).and_return(true, false)

    expect do
      post "/feed_events",
           params: { feed_events: [event_params] },
           headers: { "X-CSRF-Token" => csrf_token }
    end.to change(FeedEvent, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(FeedEvent.last.user_id).to eq(user.id)
  end

  it "authenticates POST /feed_config_visits from an unloaded Redis session" do
    establish_lazy_redis_session(user)
    allow(Feeds::RecordConfigVisit).to receive(:call).and_return(10.seconds.from_now)

    post "/feed_config_visits", params: {
      visit_token: "valid-token",
      event_id: SecureRandom.uuid
    }

    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(Feeds::RecordConfigVisit).to have_received(:call).with(
      hash_including(user_id: user.id),
    )
  end

  it "authenticates POST /page_views and PUT /page_views/:id from an unloaded Redis session" do
    establish_lazy_redis_session(user)

    sidekiq_perform_enqueued_jobs do
      post "/page_views", params: { article_id: article.id }
    end

    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(PageView.last.user_id).to eq(user.id)

    put "/page_views/#{article.id}"
    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(PageView.last.reload.time_tracked_in_seconds).to eq(30)
  end

  it "authenticates POST /bb_tabulations and PATCH /bb_tabulations/:id from an unloaded Redis session" do
    establish_lazy_redis_session(user)

    expect do
      post bb_tabulations_path,
           params: {
             billboard_event: {
               context_type: "home",
               category: "impression",
               billboard_id: billboard.id,
               article_id: article.id
             }
           }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
    end.to change(BillboardEvent, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    event = BillboardEvent.last
    expect(event.user_id).to eq(user.id)

    event.update_column(:updated_at, 10.seconds.ago)
    patch "/bb_tabulations/#{event.id}"
    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(event.reload.seconds_visible).to eq(20)
  end

  it "authenticates POST /fallback_activity_recorder (GaEventsController) from an unloaded Redis session" do
    establish_lazy_redis_session(user)
    allow(Settings::General).to receive_messages(ga_analytics_4_id: "G-TEST", ga_api_secret: "secret")
    allow(Ga::TrackEventWorker).to receive(:perform_async)

    post "/fallback_activity_recorder", params: {
      path: "/example",
      document_path: "https://localhost/example",
      user_language: "en"
    }.to_json

    expect(response).to have_http_status(:ok)
    expect(request.session_options[:skip]).to be(true)
    expect(Ga::TrackEventWorker).to have_received(:perform_async).with(
      kind_of(String),
      hash_including("user_id" => user.id),
    )
  end

  it "authenticates GET /reactions and GET /async_info/base_data from an unloaded Redis session" do
    establish_lazy_redis_session(user)

    get "/reactions", params: { article_id: article.id }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("current_user", "id")).to eq(user.id)
    expect(request.session_options[:skip]).to be(true)

    get "/async_info/base_data", headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.parsed_body["user"])["id"]).to eq(user.id)
    expect(request.session_options[:skip]).to be(true)
  end

  it "authenticates GET /follows/:id and GET /follows/bulk_show from an unloaded Redis session" do
    user.follow(other_user)
    establish_lazy_redis_session(user)

    get "/follows/#{other_user.id}", params: { followable_type: "User" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("true")
    expect(request.session_options[:skip]).to be(true)

    get bulk_show_follows_path, params: { ids: [other_user.id, user.id], followable_type: "User" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(other_user.id.to_s => "true", user.id.to_s => "self")
    expect(request.session_options[:skip]).to be(true)
  end
end
