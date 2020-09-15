require "rails_helper"

RSpec.describe "/admin/events", type: :request do
  let(:event) { create(:event) }
  let(:admin) { create(:user, :super_admin) }

  describe "PUT admin/events" do
    before do
      sign_in(admin)
    end

    it "marks an event as not live now" do
      event.update(live_now: true)
      patch "/admin/events/#{event.id}", params: { event: { live_now: "0" } }
      expect(event.reload.live_now).to eq false
    end

    it "marks an event as live now" do
      patch "/admin/events/#{event.id}", params: { event: { live_now: "1" } }
      expect(event.reload.live_now).to eq true
    end
  end
end
