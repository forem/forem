require "rails_helper"

RSpec.describe "Api::V0::EventMemberships and Event Hierarchy API" do
  let!(:admin) { create(:user, :super_admin) }
  let!(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:admin_headers) { { "api-key" => admin_api_secret.secret, "content-type" => "application/json" } }

  let!(:user) { create(:user) }
  let!(:user_api_secret) { create(:api_secret, user: user) }
  let!(:user_headers) { { "api-key" => user_api_secret.secret, "content-type" => "application/json" } }

  let!(:conference) do
    create(:event, type_of: :conference, title: "ForemConf 2026", published: true,
                   start_time: 1.day.ago, end_time: 2.days.from_now)
  end
  let!(:live_stream) do
    create(:event, type_of: :live_stream, title: "Live Keynote", published: true,
                   start_time: 30.minutes.ago, end_time: 1.hour.from_now)
  end
  let!(:upcoming_stream) do
    create(:event, type_of: :live_stream, title: "Upcoming Workshop", published: true,
                   start_time: 3.hours.from_now, end_time: 4.hours.from_now)
  end
  let!(:draft_stream) do
    create(:event, type_of: :live_stream, title: "Draft Backstage Stream", published: false,
                   start_time: 10.minutes.ago, end_time: 1.hour.from_now)
  end

  before do
    create(:event_membership, parent_event: conference, child_event: live_stream,
                              position: 0, role: "Keynote", featured: true)
    create(:event_membership, parent_event: conference, child_event: upcoming_stream, position: 1, role: "Workshop")
    create(:event_membership, parent_event: conference, child_event: draft_stream, position: 2, role: "Backstage")
  end

  describe "GET /api/events/:event_id/memberships" do
    it "returns visible sub-events and live hero schedule for guests without leaking drafts" do
      get "/api/events/#{conference.id}/memberships"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["event_id"]).to eq(conference.id)
      expect(json["hero_state"]).to eq("live")
      expect(json["hero_sub_event"]["id"]).to eq(live_stream.id)
      expect(json["live_sub_events"].pluck("id")).to eq([live_stream.id])
      expect(json["upcoming_sub_events"].pluck("id")).to eq([upcoming_stream.id])
      expect(json["sub_events"].pluck("id")).to contain_exactly(live_stream.id, upcoming_stream.id)
    end

    it "includes draft sub-events for administrators" do
      get "/api/events/#{conference.id}/memberships", headers: admin_headers

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["sub_events"].pluck("id")).to contain_exactly(live_stream.id, upcoming_stream.id, draft_stream.id)
    end

    it "returns 404 when a guest requests memberships of a draft event" do
      get "/api/events/#{draft_stream.id}/memberships"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/events/:event_id/memberships" do
    let!(:new_session) { create(:event, type_of: :live_stream, title: "Lightning Talks", published: true) }

    before { Audit::Subscribe.listen :admin_api }
    after { Audit::Subscribe.forget :admin_api }

    it "blocks unauthenticated and regular users" do
      post "/api/events/#{conference.id}/memberships",
           params: { event_membership: { child_event_id: new_session.id } }.to_json,
           headers: { "content-type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)

      post "/api/events/#{conference.id}/memberships",
           params: { event_membership: { child_event_id: new_session.id } }.to_json,
           headers: user_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "allows admins to attach a sub-event and logs an audit entry" do
      payload = {
        event_membership: { child_event_id: new_session.id, role: "Lightning", featured: true }
      }.to_json

      expect do
        post "/api/events/#{conference.id}/memberships", params: payload, headers: admin_headers
      end.to change(EventMembership, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "child_event_id" => new_session.id,
        "role" => "Lightning",
        "featured" => true,
      )
      expect(response.parsed_body.dig("child_event", "title")).to eq("Lightning Talks")

      log = AuditLog.last
      expect(log.slug).to eq("api_event_membership_create")
      expect(log.data).to include("event_id" => conference.id, "child_event_id" => new_session.id)
    end

    it "rejects self-reference, duplicates, and circular hierarchies with 422" do
      post "/api/events/#{conference.id}/memberships",
           params: { event_membership: { child_event_id: conference.id } }.to_json,
           headers: admin_headers
      expect(response).to have_http_status(:unprocessable_entity)

      post "/api/events/#{conference.id}/memberships",
           params: { event_membership: { child_event_id: live_stream.id } }.to_json,
           headers: admin_headers
      expect(response).to have_http_status(:unprocessable_entity)

      post "/api/events/#{live_stream.id}/memberships",
           params: { event_membership: { child_event_id: conference.id } }.to_json,
           headers: admin_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"].join).to include("circular")
    end
  end

  describe "PATCH and DELETE /api/events/:event_id/memberships/:id" do
    let(:membership) { EventMembership.find_by!(parent_event: conference, child_event: upcoming_stream) }

    before { Audit::Subscribe.listen :admin_api }
    after { Audit::Subscribe.forget :admin_api }

    it "updates role, position, and featured status and logs audit entry" do
      patch "/api/events/#{conference.id}/memberships/#{membership.id}",
            params: { event_membership: { role: "Main Stage", position: 0, featured: true } }.to_json,
            headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(membership.reload).to have_attributes(role: "Main Stage", position: 0, featured: true)
      expect(AuditLog.last.slug).to eq("api_event_membership_update")
    end

    it "detaches the membership without deleting the underlying child event" do
      expect do
        delete "/api/events/#{conference.id}/memberships/#{membership.id}", headers: admin_headers
      end.to change(EventMembership, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(Event.exists?(upcoming_stream.id)).to be(true)
      expect(AuditLog.last.slug).to eq("api_event_membership_destroy")
    end
  end

  describe "GET /api/events hierarchy filters and expanded payloads" do
    it "supports scope=top_level, parent_event_id, and child_event_id filters" do
      get "/api/events", params: { scope: "top_level" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).to eq([conference.id])

      get "/api/events", params: { parent_event_id: conference.id }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).to contain_exactly(live_stream.id, upcoming_stream.id)

      get "/api/events", params: { child_event_id: live_stream.id }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).to eq([conference.id])
    end

    it "expands hierarchy and schedule summaries when members=true" do
      get "/api/events", params: { scope: "top_level", members: "true" }
      expect(response).to have_http_status(:ok)
      conf_json = response.parsed_body.first
      expect(conf_json["sub_event_ids"]).to eq([live_stream.id, upcoming_stream.id])
      expect(conf_json.dig("schedule", "hero_state")).to eq("live")
      expect(conf_json.dig("schedule", "hero_sub_event", "id")).to eq(live_stream.id)
    end

    it "includes parent_events, sub_events, and schedule on GET /api/events/:id" do
      get "/api/events/#{live_stream.id}"
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["parent_event_ids"]).to eq([conference.id])
      expect(json["parent_events"].first["id"]).to eq(conference.id)
    end
  end

  describe "atomic hierarchy syncing via POST / PATCH /api/events" do
    it "creates a sub-event linked to parent_event_ids atomically" do
      payload = {
        event: {
          title: "New Sub Session",
          event_name_slug: "foremconf-2026",
          event_variation_slug: "sub-session",
          type_of: "live_stream",
          start_time: 5.hours.from_now.iso8601,
          end_time: 6.hours.from_now.iso8601,
          published: false,
          parent_event_ids: [conference.id]
        }
      }.to_json

      expect do
        post "/api/events", params: payload, headers: admin_headers
      end.to change(Event, :count).by(1).and change(EventMembership, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["parent_event_ids"]).to eq([conference.id])
    end

    it "rolls back event creation if parent_event_ids contains a nonexistent event" do
      payload = {
        event: {
          title: "Broken Sub Session",
          event_name_slug: "foremconf-2026",
          event_variation_slug: "broken-session",
          start_time: 5.hours.from_now.iso8601,
          end_time: 6.hours.from_now.iso8601,
          parent_event_ids: [999_999]
        }
      }.to_json

      expect do
        post "/api/events", params: payload, headers: admin_headers
      end.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates sub_event_memberships atomically and rolls back on cycle" do
      patch "/api/events/#{conference.id}",
            params: {
              event: {
                sub_event_memberships: [
                  { child_event_id: upcoming_stream.id, position: 0, role: "Closing Keynote", featured: true },
                ]
              }
            }.to_json,
            headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(conference.reload.sub_events).to eq([upcoming_stream])
      expect(conference.child_event_memberships.first).to have_attributes(role: "Closing Keynote", featured: true)

      patch "/api/events/#{upcoming_stream.id}",
            params: { event: { sub_event_ids: [conference.id] } }.to_json,
            headers: admin_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(upcoming_stream.reload.sub_events).to be_empty
    end
  end
end
