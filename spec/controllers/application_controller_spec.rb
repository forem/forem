require "rails_helper"

RSpec.describe "ApplicationController", type: :request do
  let!(:user) { create(:user) }
  let!(:controller) { ApplicationController.new }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "#authenticate_user!" do
    it "accepts Devise authentication options" do
      expect(controller.authenticate_user!(force: true)).to be(true)
    end
  end

  describe "#feature_flag_enabled?" do
    it "calls FeatureFlag.enabled_for_user with current_user" do
      allow(FeatureFlag).to receive(:enabled_for_user?)
      controller.feature_flag_enabled?("flag_name")
      expect(FeatureFlag).to have_received(:enabled_for_user?)
        .with("flag_name", user)
    end
  end

  describe "#set_unauthenticated_session_expiry" do
    let(:mock_request) { instance_double(ActionDispatch::Request, session_options: {}) }

    before do
      allow(controller).to receive(:request).and_return(mock_request)
    end

    context "when user is not signed in" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
      end

      it "sets session expire_after to 2 days" do
        controller.send(:set_unauthenticated_session_expiry)
        expect(mock_request.session_options[:expire_after]).to eq(2.days.to_i)
      end
    end

    context "when user is signed in" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
      end

      it "does not alter expire_after, relying on the global default" do
        controller.send(:set_unauthenticated_session_expiry)
        expect(mock_request.session_options[:expire_after]).to be_nil
      end
    end
  end

  describe "#valid_request_origin?" do
    let(:mock_request) do
      instance_double(
        ActionDispatch::Request,
        referer: referer,
        host: "dev.to",
        port: 443,
      )
    end

    before do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(controller).to receive(:request).and_return(mock_request)
    end

    context "when referer matches the request host and port" do
      let(:referer) { "https://dev.to/some-post" }

      it "returns true" do
        expect(controller.valid_request_origin?).to be(true)
      end
    end

    context "when referer contains an invalid URI or non-ASCII bytes" do
      let(:referer) { "1 \xC0\xA7\xC0\xA2%2527%2522".b }

      it "returns false instead of raising URI::InvalidURIError" do
        expect(controller.valid_request_origin?).to be(false)
      end
    end
  end
end
