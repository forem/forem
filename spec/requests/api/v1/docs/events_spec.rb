require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Events" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:admin) { create(:user, :super_admin) }
  let(:admin_api_secret) { create(:api_secret, user: admin) }
  let(:regular_user) { create(:user) }
  let(:user_api_secret) { create(:api_secret, user: regular_user) }
  let!(:published_event) { create(:event, published: true, bg_color_hex: "#3B49DF", elevated: true) }
  let!(:draft_event) { create(:event, published: false) }

  describe "GET /api/events" do
    path "/api/events" do
      get "Retrieve all accessible events" do
        tags "events"
        description <<~DESCRIBE.strip
          Retrieve a list of events.

          ### Events Overview:
          - Events represent community live streams, hackathons/challenges, takeovers, or digital gatherings.
          - Unauthenticated or non-admin requests only return published events ordered chronologically.
          - Administrators can view all events including unpublished drafts.

          ### Query Parameters:
          - **type_of**: Filter events by their category (`live_stream`, `takeover`, `other`, `challenge`).
        DESCRIBE
        operationId "getEvents"
        produces "application/json"
        parameter name: :type_of,
                  in: :query,
                  required: false,
                  description: "Filter events by type (`live_stream`, `takeover`, `other`, `challenge`).",
                  schema: {
                    type: :string,
                    enum: %w[live_stream takeover other challenge]
                  }

        response "200", "A list of events" do
          let(:"api-key") { nil }
          let(:type_of) { nil }
          schema type: :array, items: { "$ref": "#/components/schemas/Event" }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/events" do
    path "/api/events" do
      post "Create a new event" do
        tags "events"
        description <<~DESCRIBE.strip
          Create a new event. Requires administrator privileges.

          ### Parameter Guidelines:
          - **title**: Heading or name of the event.
          - **event_name_slug**: URL grouping identifier (e.g. `community-stream`).
          - **event_variation_slug**: Variation key under the event name (e.g. `ep-1`, `2026`).
          - **full_details**: Full markdown text dump for event agenda, speakers, and instructions.
          - **start_time** & **end_time**: ISO 8601 timestamps defining the event timeframe.
          - **type_of**: Event category (`live_stream`, `takeover`, `challenge`, `other`).
          - **cover_image_url**: Direct image URL to automatically download and store as the event cover image.
          - **bg_color_hex**: 6-digit hex code for custom header/badge styling (e.g. `#3B49DF`).
          - **elevated**: Set to `true` to pin and highlight in upcoming events banners.
        DESCRIBE
        operationId "createEvent"
        consumes "application/json"
        produces "application/json"

        parameter name: :event_params, in: :body,
                  description: "Event creation payload",
                  schema: { "$ref": "#/components/schemas/EventParam" }

        let(:event_params) do
          {
            event: {
              title: "Global Community Live Stream",
              event_name_slug: "global-stream",
              event_variation_slug: "kickoff",
              description: "Live interactive coding and community updates",
              full_details: "Full speaker line-up, detailed schedule breakdown, and workshop instructions.",
              primary_stream_url: "https://twitch.tv/ThePracticalDev",
              start_time: 1.day.from_now.iso8601,
              end_time: 2.days.from_now.iso8601,
              type_of: "live_stream",
              broadcast_config: "tagged_broadcast",
              bg_color_hex: "#3B49DF",
              elevated: true,
              published: true,
              tag_list: "discuss, livestream"
            }
          }
        end

        response "201", "Event created" do
          let(:"api-key") { admin_api_secret.secret }
          schema "$ref": "#/components/schemas/Event"
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { user_api_secret.secret }
          add_examples
          run_test!
        end

        response "422", "unprocessable entity" do
          let(:"api-key") { admin_api_secret.secret }
          let(:event_params) { { event: { title: "" } } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "GET /api/events/{id}" do
    path "/api/events/{id}" do
      get "Retrieve a single event" do
        tags "events"
        description <<~DESCRIBE.strip
          Retrieve details for an event by ID.

          ### Access Control:
          - Public users can view published events.
          - Viewing unpublished/draft events requires administrator privileges.
        DESCRIBE
        operationId "getEventById"
        produces "application/json"

        parameter name: :id, in: :path, required: true,
                  description: "Unique event ID",
                  schema: { type: :integer },
                  example: 1

        let(:id) { published_event.id }

        response "200", "Event details" do
          let(:"api-key") { nil }
          schema "$ref": "#/components/schemas/Event"
          add_examples
          run_test!
        end

        response "404", "event not found" do
          let(:"api-key") { nil }
          let(:id) { draft_event.id }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /api/events/{id}" do
    path "/api/events/{id}" do
      put "Update an existing event" do
        tags "events"
        description <<~DESCRIBE.strip
          Update metadata, schedule, cover image, or styling for an event. Requires administrator privileges.
        DESCRIBE
        operationId "updateEvent"
        consumes "application/json"
        produces "application/json"

        parameter name: :id, in: :path, required: true,
                  description: "Unique event ID",
                  schema: { type: :integer },
                  example: 1

        parameter name: :event_params, in: :body,
                  description: "Event update payload",
                  schema: { "$ref": "#/components/schemas/EventParam" }

        let(:id) { published_event.id }
        let(:event_params) do
          {
            event: {
              title: "Updated Stream Title",
              full_details: "Updated comprehensive agenda and FAQ dump",
              bg_color_hex: "#7C3AED",
              elevated: false
            }
          }
        end

        response "200", "Event updated" do
          let(:"api-key") { admin_api_secret.secret }
          schema "$ref": "#/components/schemas/Event"
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { user_api_secret.secret }
          add_examples
          run_test!
        end

        response "404", "event not found" do
          let(:"api-key") { admin_api_secret.secret }
          let(:id) { 999_999 }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "DELETE /api/events/{id}" do
    path "/api/events/{id}" do
      delete "Delete an event" do
        tags "events"
        description "Delete an event. Requires administrator privileges."
        operationId "deleteEvent"

        parameter name: :id, in: :path, required: true,
                  description: "Unique event ID",
                  schema: { type: :integer },
                  example: 1

        let(:id) { draft_event.id }

        response "204", "event deleted" do
          let(:"api-key") { admin_api_secret.secret }
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { user_api_secret.secret }
          add_examples
          run_test!
        end
      end
    end
  end
end

# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
