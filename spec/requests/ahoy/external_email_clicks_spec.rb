# spec/requests/ahoy_messages_controller_spec.rb

require "rails_helper"

RSpec.describe "ExternalAhoyEmailClicks" do
  describe "GET #click" do
    let(:user) { create(:user) } # Adjust this line based on your user model
    let(:bb_value) { "test_bb_value" }
    let(:url_with_bb) { "http://example.com?bb=#{bb_value}" }
    let(:url_without_bb) { "http://example.com" }
    let(:token) { "test_token" }
    let(:signature) { "test_signature" }

    before do
      # Stub signature verification
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_return(true)
      # Stub current_user
      allow_any_instance_of(Ahoy::MessagesController).to receive(:current_user).and_return(user)
      # Clear Sidekiq jobs before each test
      Billboards::TrackEmailClickWorker.clear
    end

    context "when bb parameter is present in the URL" do
      it "enqueues Billboards::TrackEmailClickWorker with bb and current_user" do
        expect do
          get "/ahoy/click", params: { u: url_with_bb, t: token }
        end.to change(Billboards::TrackEmailClickWorker.jobs, :size).by(1)

        job = Billboards::TrackEmailClickWorker.jobs.last
        expect(job["args"]).to eq([bb_value, user.id])

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(url_with_bb)
      end
    end

    context "when bb parameter is not present in the URL" do
      it "does not enqueue Billboards::TrackEmailClickWorker" do
        expect do
          get "/ahoy/click", params: { u: url_without_bb, t: token }
        end.not_to change(Billboards::TrackEmailClickWorker.jobs, :size)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(url_without_bb)
      end
    end
  end
end
