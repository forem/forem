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
- **type_of**: Filter events by their type (`live_stream`, `takeover`, `other`, `challenge`)."
        operationId "getEvents"
        produces "application/json"
        parameter name: :type_of,
                  in: :query,
                  required: false,
                  description: "Filter events by type.",
                  schema: {
                    type: :string,
                    enum: %w[live_stream takeover other challenge]
                  }

        response "200", "A list of events" do
          let(:type_of) { "challenge" }
          schema type: :array, items: { "$ref": "#/components/schemas/Event" }
          add_examples

          run_test!
        end
      end

      post "Create an event" do
        tags "events"
        description "Create a new event. Requires administrator privileges."
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
        description "Retrieve a single event by ID."
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
        description "Update an existing event. Requires administrator privileges."
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
        description "Delete an event. Requires administrator privileges."
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
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
