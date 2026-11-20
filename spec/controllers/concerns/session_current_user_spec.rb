require "rails_helper"

RSpec.describe SessionCurrentUser do
  let(:user) { create(:user) }
  let(:controller_class) do
    Class.new(ApplicationMetalController) do
      def self.name
        "AnonymousMetalSessionController"
      end
    end
  end

  def build_controller_with_unloaded_session(session_payload:, skip_before_read: false, cookies_hash: {})
    controller = controller_class.new
    env = Rack::MockRequest.env_for("http://localhost/test")
    by_store = Class.new do
      define_method(:load_session) do |req|
        if req.session.options[:skip]
          ["skipped-sid", {}]
        else
          ["loaded-sid", session_payload]
        end
      end

      def session_exists?(_req)
        true
      end
    end.new

    req = ActionDispatch::Request.new(env)
    ActionDispatch::Request::Session.create(by_store, req, {})
    req.session_options[:skip] = true if skip_before_read
    cookies_hash.each { |k, v| req.cookie_jar[k] = v }
    controller.set_request!(req)
    controller.set_response!(ActionDispatch::Response.new)
    controller
  end

  describe "#session_current_user_id" do
    it "loads the user ID from an unloaded session even when session_options[:skip] was pre-set to true" do
      session_payload = { "warden.user.user.key" => [[user.id], user.authenticatable_salt] }
      controller = build_controller_with_unloaded_session(
        session_payload: session_payload,
        skip_before_read: true,
      )

      expect(controller.request.session).not_to be_loaded
      expect(controller.session_current_user_id).to eq(user.id)
      expect(controller.request.session).to be_loaded
      expect(controller.request.session_options[:skip]).to be(true)
    end
  end

  describe "#session_or_remembered_user_id" do
    it "validates authenticatable_salt and loads an unloaded session even when session_options[:skip] was true" do
      session_payload = { "warden.user.user.key" => [[user.id], user.authenticatable_salt] }
      controller = build_controller_with_unloaded_session(
        session_payload: session_payload,
        skip_before_read: true,
      )

      expect(controller.session_or_remembered_user_id).to eq(user.id)
      expect(controller.request.session_options[:skip]).to be(true)
    end

    it "returns nil when the session authenticatable_salt does not match the user's encrypted_password" do
      session_payload = { "warden.user.user.key" => [[user.id], "$2a$10$stale_salt_value_000000"] }
      controller = build_controller_with_unloaded_session(
        session_payload: session_payload,
        skip_before_read: true,
      )

      expect(controller.session_or_remembered_user_id).to be_nil
      expect(controller.request.session_options[:skip]).to be(true)
    end
  end

  describe "#valid_session_viewer?" do
    it "validates a preloaded viewer against an unloaded session even when session_options[:skip] was true" do
      session_payload = { "warden.user.user.key" => [[user.id], user.authenticatable_salt] }
      controller = build_controller_with_unloaded_session(
        session_payload: session_payload,
        skip_before_read: true,
      )
      viewer = User.select(:id, :encrypted_password).find_by(id: user.id)

      expect(controller.valid_session_viewer?(viewer)).to be(true)
      expect(controller.request.session_options[:skip]).to be(true)
    end
  end
end
