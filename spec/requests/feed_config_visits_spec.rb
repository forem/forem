require "rails_helper"

RSpec.describe "Feed config visibility visits" do
  let(:user) { create(:user) }
  let(:config) { create(:feed_config, feed_impression_users_count: 2) }
  let(:assignment) do
    create(:feed_config_assignment, user: user, feed_config: config, last_rewarded_at: 1.hour.ago)
  end
  let(:token) { assignment.visit_token(host: "forem.test") }
  let(:event_id) { SecureRandom.uuid }
  let(:params) { { visit_token: token, event_id: event_id } }

  around do |example|
    previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rack::Attack.cache.store = previous_store
  end

  before do
    host! "forem.test"
    sign_in user
  end

  it "credits a visible return immediately and supplies the remaining cooldown" do
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Feed-Visit-Wait"]).to eq("1800")
    expect(response.headers["Cache-Control"]).to eq("private, no-store")
    expect(config.reload).to have_attributes(feed_repeat_visits_count: 1, feed_success_score: 0.5)
    expect(assignment.reload.repeat_visits_count).to eq(1)
  end

  it "credits 1.5 clicks per return for power-user configurations" do
    config.update!(targeting_bucket: FeedConfig::BUCKET_FEED_POWER_USER)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:ok)
    expect(config.reload).to have_attributes(feed_repeat_visits_count: 1, feed_success_score: 0.75)
  end

  it "stops awarding credit once an assignment reaches 20 repeat visits" do
    assignment.update!(repeat_visits_count: 19)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:ok)
    expect(config.reload.feed_repeat_visits_count).to eq(1)
    expect(assignment.reload.repeat_visits_count).to eq(20)

    Timecop.travel(31.minutes.from_now) do
      expect do
        post feed_config_visits_path, params: params.merge(event_id: SecureRandom.uuid)
      end.not_to change(FeedEventReceipt, :count)
      expect(response).to have_http_status(:no_content)
      expect(config.reload.feed_repeat_visits_count).to eq(1)
      expect(assignment.reload.repeat_visits_count).to eq(20)
    end
  end

  it "establishes the first visible exposure without rewarding the initial display" do
    assignment.update!(last_rewarded_at: nil)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:ok)
    expect(assignment.reload.last_rewarded_at).to be_present
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "never turns a replayed visit into fresh credit after the cooldown" do
    post feed_config_visits_path, params: params
    Timecop.travel(31.minutes.from_now) do
      expect { post feed_config_visits_path, params: params }.not_to change { config.reload.feed_repeat_visits_count }
      post feed_config_visits_path, params: params.merge(event_id: SecureRandom.uuid)
      expect(config.reload.feed_repeat_visits_count).to eq(2)
    end
  end

  it "also remembers events suppressed by the cooldown" do
    assignment.update!(last_rewarded_at: Time.current)
    expect { post feed_config_visits_path, params: params }.not_to change { config.reload.feed_repeat_visits_count }
    Timecop.travel(31.minutes.from_now) do
      expect { post feed_config_visits_path, params: params }.not_to change { config.reload.feed_repeat_visits_count }
      post feed_config_visits_path, params: params.merge(event_id: SecureRandom.uuid)
      expect(config.reload.feed_repeat_visits_count).to eq(1)
    end
  end

  it "safely rejects an ID already reserved by a different feed event before initial visibility" do
    assignment.update!(last_rewarded_at: nil)
    FeedEventReceipt.create!(id: event_id)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:no_content)
    expect(assignment.reload.last_rewarded_at).to be_nil
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "rejects another account's proof without reserving its event ID" do
    token
    sign_in create(:user)
    expect { post feed_config_visits_path, params: params }.not_to change(FeedEventReceipt, :count)
    expect(response).to have_http_status(:no_content)
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "rejects a token copied from another host" do
    params[:visit_token] = assignment.visit_token(host: "other.forem.test")
    expect { post feed_config_visits_path, params: params }.not_to change(FeedEventReceipt, :count)
    expect(response).to have_http_status(:no_content)
  end

  it "rejects tampering and tokens signed for another purpose" do
    params[:visit_token] = "#{token}tampered"
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:no_content)
    params[:visit_token] = FeedConfigAssignment.visit_verifier.generate({}, purpose: :other)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:no_content)
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "rejects expired proofs" do
    token
    Timecop.travel(61.hours.from_now) do
      expect { post feed_config_visits_path, params: params }.not_to change(FeedEventReceipt, :count)
      expect(response).to have_http_status(:no_content)
    end
  end

  it "rejects an old window's proof even when the same configuration is reassigned" do
    original_token = token
    assignment.update!(expires_at: 72.hours.from_now, last_rewarded_at: 1.hour.ago)
    post feed_config_visits_path, params: params.merge(visit_token: original_token)
    expect(response).to have_http_status(:no_content)
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "acknowledges archived and deleted configurations without credit" do
    token
    config.update!(archived: true)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:no_content)
    config.destroy!
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:no_content)
  end

  it "respects subforem settings from the signed assignment" do
    subforem = create(:subforem)
    assignment.update!(subforem: subforem)
    allow(Subforem).to receive(:cached_id_by_domain).and_return(subforem.id)
    Settings::UserExperience.set_feed_config_repeat_visit_minutes(90, subforem_id: subforem.id)
    assignment.update!(last_rewarded_at: 45.minutes.ago)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:ok)
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "rejects a proof when the request's subforem differs from the serving context" do
    token
    subforem = create(:subforem)
    allow(Subforem).to receive(:cached_id_by_domain).and_return(subforem.id)
    expect { post feed_config_visits_path, params: params }.not_to change(FeedEventReceipt, :count)
    expect(response).to have_http_status(:no_content)
  end

  it "stops credit when sticky feeds are disabled after selection" do
    token
    allow(Settings::UserExperience).to receive(:feed_config_sticky_percentage).and_return(0)
    post feed_config_visits_path, params: params
    expect(response).to have_http_status(:no_content)
    expect(config.reload.feed_repeat_visits_count).to eq(0)
  end

  it "respects the browser-event incident switch" do
    allow(FeatureFlag).to receive(:enabled?).with(:disable_browser_feed_events).and_return(true)
    expect { post feed_config_visits_path, params: params }.not_to change(FeedEventReceipt, :count)
    expect(response).to have_http_status(:no_content)
  end

  it "ignores signed-out clients" do
    token
    sign_out user
    expect { post feed_config_visits_path, params: params }.not_to change(FeedEventReceipt, :count)
    expect(response).to have_http_status(:no_content)
  end

  it "supports bearer-token authentication" do
    token
    sign_out user
    jwt = JWT.encode({ "user_id" => user.id }, Rails.application.secret_key_base, "HS256")
    post feed_config_visits_path, params: params, headers: { "Authorization" => "Bearer #{jwt}" }
    expect(response).to have_http_status(:ok)
    expect(config.reload.feed_repeat_visits_count).to eq(1)
  end

  context "with production CSRF callbacks enabled" do
    before do
      # Metal omits the inherited CSRF callback in test. Load the endpoint under
      # a protected base to exercise the same callback order as production.
      protected_base = Class.new(ApplicationMetalController)
      protected_base.protect_from_forgery with: :exception, prepend: true
      protected_base.allow_forgery_protection = true
      stub_const("ApplicationMetalController", protected_base)
      stub_const("FeedConfigVisitsController", Class.new(protected_base))
      load Rails.root.join("app/controllers/feed_config_visits_controller.rb")
    end

    it "authenticates a bearer request before checking its missing CSRF token" do
      token
      sign_out user
      jwt = JWT.encode({ "user_id" => user.id }, Rails.application.secret_key_base, "HS256")
      post feed_config_visits_path, params: params, headers: { "Authorization" => "Bearer #{jwt}" }
      expect(response).to have_http_status(:ok)
      expect(config.reload.feed_repeat_visits_count).to eq(1)
    end

    it "still rejects a session request without a CSRF token" do
      expect { post feed_config_visits_path, params: params }.to raise_error(ActionController::InvalidAuthenticityToken)
      expect(config.reload.feed_repeat_visits_count).to eq(0)
    end

    it "does not let an invalid bearer token bypass CSRF verification" do
      expect do
        post feed_config_visits_path, params: params, headers: { "Authorization" => "Bearer invalid" }
      end.to raise_error(ActionController::InvalidAuthenticityToken)
      expect(config.reload.feed_repeat_visits_count).to eq(0)
    end
  end

  [nil, "invalid", [], {}].each do |invalid|
    it "rejects a malformed event ID #{invalid.inspect}" do
      post feed_config_visits_path, params: params.merge(event_id: invalid), as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  it "bounds token size before signature verification" do
    post feed_config_visits_path, params: params.merge(visit_token: "x" * 4097)
    expect(response).to have_http_status(:bad_request)
  end

  it "bounds admission per authenticated user" do
    allow(Feeds::RecordConfigVisit).to receive(:call).and_return(30.minutes.from_now)
    # Keep every request in the same Rack::Attack fixed minute window.
    Timecop.freeze do
      60.times { post feed_config_visits_path, params: params }
      post feed_config_visits_path, params: params
    end
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("60")
    expect(Feeds::RecordConfigVisit).to have_received(:call).exactly(60).times
  end

  it "rolls back receipts and cooldowns if scoring fails" do
    allow(FeedConfig).to receive(:record_repeat_visit).and_raise(ActiveRecord::StatementInvalid)
    expect { post feed_config_visits_path, params: params }.to raise_error(ActiveRecord::StatementInvalid)
    expect(FeedEventReceipt.exists?(id: event_id)).to be(false)
    expect(assignment.reload.last_rewarded_at).to be < 30.minutes.ago
    allow(FeedConfig).to receive(:record_repeat_visit).and_call_original
    post feed_config_visits_path, params: params
    expect(config.reload.feed_repeat_visits_count).to eq(1)
  end
end
