require "rails_helper"

RSpec.describe "/admin/apps/events", type: :request do
  let(:event) { create(:event, title: "Hey") }
  let(:admin) { create(:user, :super_admin) }
  let(:params) do
    {
      event: {
        title: "Hello, world!",
        description_markdown: "This is an event",
        starts_at: Time.current,
        ends_at: 3660.seconds.from_now,
        category: "Talk"
      }
    }
  end

  describe "PUT admin/apps/events" do
    before do
      sign_in(admin)
    end

    it "marks an event as not live now" do
      event.update(live_now: true)
      patch admin_event_path(event.id), params: { event: { live_now: "0" } }
      expect(event.reload.live_now).to eq false
    end

    it "marks an event as live now" do
      patch admin_event_path(event.id), params: { event: { live_now: "1" } }
      expect(event.reload.live_now).to eq true
    end

    it "successfully updates the event title" do
      expect do
        patch admin_event_path(event.id), params: params
      end.to change { event.reload.title }.to("Hello, world!")
    end
  end

  describe "POST /admin/apps/events" do
    let(:post_resource) { post admin_events_path, params: params }

    before { sign_in admin }

    it "successfully creates an event" do
      expect do
        post_resource
      end.to change { Event.all.count }.by(1)
    end
  end
end
