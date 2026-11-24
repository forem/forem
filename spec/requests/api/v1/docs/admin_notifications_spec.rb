require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::AdminNotifications" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:recipient) { create(:user) }
  let(:admin_notification) do
    Notifications::AdminNotifications::Send.call(user_ids: [recipient.id], content: { "title" => "Your MLH application" })
    Notification.where(notifiable_type: "AdminNotification").last
  end

  before { api_secret.user.add_role(:super_admin) }

  content_schema = {
    title: { type: :string, description: "Plain text, at most 250 characters." },
    body: { type: :string, nullable: true, description: "Plain text, at most 1,000 characters. Line breaks are kept." },
    url: { type: :string, nullable: true, description: "An absolute http(s) URL or a same-site path starting with /." }
  }

  describe "POST /api/admin/notifications" do
    path "/api/admin/notifications" do
      post "Create notifications (Admin)" do
        tags "notifications", "admin"
        description "Pushes one notification to each listed user and returns each user's DEV notification id. Users that don't exist are reported as not_found and skipped. The notification appears on the user's /notifications page. Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :notification_params, in: :body,
                  schema: {
                    type: :object,
                    properties: {
                      user_ids: { type: :array, items: { type: :integer }, minItems: 1, maxItems: 1_000,
                                  description: "DEV user ids, 1 to 1,000." },
                      actor_id: { type: :integer, description: "Optional DEV user whose avatar the notification shows." },
                      **content_schema
                    },
                    required: %w[user_ids title]
                  }

        response "201", "created" do
          let(:"api-key") { api_secret.secret }
          let(:notification_params) do
            { user_ids: [recipient.id, 999_999_999], title: "Your MLH application", body: "You're in!", url: "https://mlh.io" }
          end
          add_examples
          run_test!
        end

        response "422", "invalid parameters" do
          let(:"api-key") { api_secret.secret }
          let(:notification_params) { { user_ids: [recipient.id] } }
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:notification_params) { { user_ids: [recipient.id], title: "Hi" } }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "PUT /api/admin/notifications/{id}" do
    path "/api/admin/notifications/{id}" do
      put "Update a notification (Admin)" do
        tags "notifications", "admin"
        description "Edits the content of one notification created through this API, for that recipient only. Its position and read state don't change. Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }, description: "DEV notification id."
        parameter name: :notification_params, in: :body,
                  schema: { type: :object, properties: content_schema,
                            description: "Any subset; an empty body or url clears it." }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:id) { admin_notification.id }
          let(:notification_params) { { title: "Your MLH application was accepted" } }
          add_examples
          run_test!
        end

        response "404", "not found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 0 }
          let(:notification_params) { { title: "x" } }
          add_examples
          run_test!
        end
      end

      delete "Delete a notification (Admin)" do
        tags "notifications", "admin"
        description "Deletes one notification of any kind. Requires Super Admin credentials."
        produces "application/json"
        parameter name: :id, in: :path, required: true, schema: { type: :integer }, description: "DEV notification id."

        response "204", "deleted" do
          let(:"api-key") { api_secret.secret }
          let(:id) { admin_notification.id }
          run_test!
        end

        response "404", "not found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 0 }
          add_examples
          run_test!
        end
      end
    end
  end

  describe "POST /api/admin/users/{user_id}/notifications/read" do
    path "/api/admin/users/{user_id}/notifications/read" do
      post "Mark a user's notifications read (Admin)" do
        tags "notifications", "admin"
        description "Marks a user's unread notifications read up to a point, given as exactly one of up_to_id or read_through. up_to_id marks rows with an id up to it that were last notified no later than it, so a reaction or follow row re-notified after it stays unread. read_through marks rows last notified at or before that time, to the millisecond. Requires Super Admin credentials."
        consumes "application/json"
        produces "application/json"
        parameter name: :user_id, in: :path, required: true, schema: { type: :integer }, description: "DEV user id."
        parameter name: :read_params, in: :body,
                  schema: {
                    type: :object,
                    properties: {
                      up_to_id: { type: :integer, description: "One of the user's DEV notification ids." },
                      read_through: { type: :string, format: "date-time", description: "ISO 8601 time." }
                    }
                  }

        response "200", "successful" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { recipient.id }
          let(:read_params) { { up_to_id: admin_notification.id } }
          add_examples
          run_test!
        end

        response "422", "invalid cutoff" do
          let(:"api-key") { api_secret.secret }
          let(:user_id) { recipient.id }
          let(:read_params) { {} }
          add_examples
          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable Layout/LineLength
