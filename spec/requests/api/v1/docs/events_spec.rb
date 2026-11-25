require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "Api::V1::Docs::Events" do
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let!(:event) { create(:event, published: true, type_of: :challenge) }

  describe "GET /api/events" do
    path "/api/events" do
      get "Retrieve events" do
        tags "events"
        security []
        description "Retrieve a list of events on the platform.

### Query Parameters:
- **type_of**: Filter events by their type (`live_stream`, `takeover`, `other`, `challenge`, `meetup`, `conference`).
- **scope**: Set to `top_level` to exclude sub-events that belong to a parent event.
- **members**: Set to `true` to expand `parent_events`, `sub_events`, and `schedule` metadata inline.
- **parent_event_id**: Filter to sub-events belonging to a specific parent event ID.
- **child_event_id**: Filter to parent events containing a specific child event ID."
        operationId "getEvents"
        produces "application/json"
        parameter name: :type_of,
                  in: :query,
                  required: false,
                  description: "Filter events by type.",
                  schema: {
                    type: :string,
                    enum: %w[live_stream takeover other challenge meetup conference]
                  }
        parameter name: :scope,
                  in: :query,
                  required: false,
                  description: "Set to `top_level` to return only root events.",
                  schema: {
                    type: :string,
                    enum: %w[top_level]
                  }
        parameter name: :members,
                  in: :query,
                  required: false,
                  description: "Set to `true` to expand `sub_events`, `parent_events`, and `schedule`.",
                  schema: { type: :boolean }
        parameter name: :parent_event_id,
                  in: :query,
                  required: false,
                  description: "Filter to sub-events belonging to the given parent event ID.",
                  schema: { type: :integer }
        parameter name: :child_event_id,
                  in: :query,
                  required: false,
                  description: "Filter to parent events containing the given sub-event ID.",
                  schema: { type: :integer }

        response "200", "A list of events" do
          let(:type_of) { "challenge" }
          schema type: :array, items: { "$ref": "#/components/schemas/Event" }
          add_examples

          run_test!
        end
      end

      post "Create an event" do
        tags "events"
        description(<<~DESCRIBE.strip)
          Create a new event. Requires administrator privileges.
          Optionally pass `parent_event_ids`, `sub_event_ids`, or `sub_event_memberships` to link hierarchy relationships atomically.

          Successful writes log `api_event_create` with the actor and target ids in the admin API audit log.
        DESCRIBE
        operationId "createEvent"
        consumes "application/json"
        produces "application/json"
        parameter name: :event_params,
                  in: :body,
                  description: "Event parameters to create.",
                  schema: { "$ref": "#/components/schemas/EventInput" }

        response "201", "Event created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:event_params) do
            {
              event: {
                title: "Community Challenge",
                event_name_slug: "community-challenge",
                event_variation_slug: "2026",
                start_time: 1.day.from_now.iso8601,
                end_time: 2.days.from_now.iso8601,
                type_of: "challenge",
                published: true
              }
            }
          end
          schema "$ref": "#/components/schemas/Event"
          add_examples

          run_test!
        end
      end
    end
  end

  describe "GET /api/events/{id}" do
    path "/api/events/{id}" do
      get "Retrieve an event" do
        tags "events"
        security []
        description "Retrieve a single event by ID with visible `parent_events`, `sub_events`, and `schedule`."
        operationId "getEventById"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "ID of the event.",
                  schema: { type: :integer }

        response "200", "The requested event" do
          let(:id) { event.id }
          schema "$ref": "#/components/schemas/Event"
          add_examples

          run_test!
        end
      end

      patch "Update an event" do
        tags "events"
        description(<<~DESCRIBE.strip)
          Update an existing event. Requires administrator privileges.
          Optionally pass `parent_event_ids`, `sub_event_ids`, or `sub_event_memberships` to synchronize hierarchy relationships atomically.

          Successful writes log `api_event_update` with the actor and target ids in the admin API audit log.
        DESCRIBE
        operationId "updateEvent"
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "ID of the event to update.",
                  schema: { type: :integer }
        parameter name: :event_params,
                  in: :body,
                  description: "Event parameters to update.",
                  schema: { "$ref": "#/components/schemas/EventInput" }

        response "200", "Event updated" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { event.id }
          let(:event_params) do
            {
              event: {
                title: "Updated Challenge Title"
              }
            }
          end
          schema "$ref": "#/components/schemas/Event"
          add_examples

          run_test!
        end
      end

      delete "Delete an event" do
        tags "events"
        description(<<~DESCRIBE.strip)
          Delete an event. Requires administrator privileges.

          Successful writes log `api_event_destroy` with the actor and target ids in the admin API audit log.
        DESCRIBE
        operationId "deleteEvent"
        parameter name: :id, in: :path, required: true,
                  description: "ID of the event to delete.",
                  schema: { type: :integer }

        response "204", "Event deleted" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { event.id }
          add_examples

          run_test!
        end
      end
    end
  end

  describe "Event Memberships" do
    let!(:conference) { create(:event, published: true, type_of: :conference, title: "Summit 2026") }
    let!(:livestream) { create(:event, published: true, type_of: :live_stream, title: "Opening Keynote") }
    let!(:second_stream) { create(:event, published: true, type_of: :live_stream, title: "Closing Panel") }
    let!(:membership) do
      create(:event_membership, parent_event: conference, child_event: livestream,
                                position: 0, role: "Keynote", featured: true)
    end

    path "/api/events/{event_id}/memberships" do
      get "Retrieve event hierarchy memberships and schedule" do
        tags "events"
        security []
        description "Retrieve an event's parent events, sub-events, and live/upcoming/past schedule hero resolution."
        operationId "getEventMemberships"
        produces "application/json"
        parameter name: :event_id, in: :path, required: true,
                  description: "ID of the event.",
                  schema: { type: :integer }

        response "200", "Event hierarchy memberships" do
          let(:event_id) { conference.id }
          schema "$ref": "#/components/schemas/EventMembershipsResponse"
          add_examples

          run_test!
        end
      end

      post "Attach a sub-event to a parent event" do
        tags "events"
        description(<<~DESCRIBE.strip)
          Attach an existing event as a sub-event of the given parent event. Requires administrator privileges.
          Enforces self-reference, duplicate, cycle, and maximum depth safeguards.

          Successful writes log `api_event_membership_create` in the admin API audit log.
        DESCRIBE
        operationId "createEventMembership"
        consumes "application/json"
        produces "application/json"
        parameter name: :event_id, in: :path, required: true,
                  description: "ID of the parent event.",
                  schema: { type: :integer }
        parameter name: :membership_params, in: :body,
                  description: "Sub-event membership attributes.",
                  schema: { "$ref": "#/components/schemas/EventMembershipInput" }

        response "201", "Event membership created" do
          let(:"api-key") { admin_api_secret.secret }
          let(:event_id) { conference.id }
          let(:membership_params) do
            {
              event_membership: {
                child_event_id: second_stream.id,
                position: 1,
                role: "Panel",
                featured: false
              }
            }
          end
          schema "$ref": "#/components/schemas/EventMembership"
          add_examples

          run_test!
        end
      end
    end

    path "/api/events/{event_id}/memberships/{id}" do
      patch "Update a sub-event membership" do
        tags "events"
        description(<<~DESCRIBE.strip)
          Update ordering, track/role label, or featured flag on a sub-event membership. Requires administrator privileges.

          Successful writes log `api_event_membership_update` in the admin API audit log.
        DESCRIBE
        operationId "updateEventMembership"
        consumes "application/json"
        produces "application/json"
        parameter name: :event_id, in: :path, required: true,
                  description: "ID of the parent event.",
                  schema: { type: :integer }
        parameter name: :id, in: :path, required: true,
                  description: "ID of the event membership.",
                  schema: { type: :integer }
        parameter name: :membership_params, in: :body,
                  description: "Updated membership attributes.",
                  schema: { "$ref": "#/components/schemas/EventMembershipInput" }

        response "200", "Event membership updated" do
          let(:"api-key") { admin_api_secret.secret }
          let(:event_id) { conference.id }
          let(:id) { membership.id }
          let(:membership_params) do
            {
              event_membership: {
                position: 0,
                role: "Main Stage Keynote",
                featured: true
              }
            }
          end
          schema "$ref": "#/components/schemas/EventMembership"
          add_examples

          run_test!
        end
      end

      delete "Detach a sub-event from a parent event" do
        tags "events"
        description(<<~DESCRIBE.strip)
          Remove the membership link between a parent event and a sub-event without deleting either event. Requires administrator privileges.

          Successful writes log `api_event_membership_destroy` in the admin API audit log.
        DESCRIBE
        operationId "deleteEventMembership"
        parameter name: :event_id, in: :path, required: true,
                  description: "ID of the parent event.",
                  schema: { type: :integer }
        parameter name: :id, in: :path, required: true,
                  description: "ID of the event membership.",
                  schema: { type: :integer }

        response "204", "Event membership deleted" do
          let(:"api-key") { admin_api_secret.secret }
          let(:event_id) { conference.id }
          let(:id) { membership.id }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
