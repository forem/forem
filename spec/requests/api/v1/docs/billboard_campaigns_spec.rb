require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "api/v1/billboard_campaigns" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }
  let(:existing_campaign) do
    BillboardCampaign.create!(
      name: "Spring Launch",
      max_impressions_count: 50_000,
      max_clicks_count: 1_000,
      ideal_daily_impressions: 5_000,
    )
  end

  before { user.add_role(:admin) }

  path "/api/billboard_campaigns" do
    describe "GET /billboard_campaigns" do
      get("Billboard campaigns") do
        tags "billboard_campaigns"
        description(<<-DESCRIBE.strip)
        Retrieve a paginated list of billboard campaigns. Requires Billboard admin privileges.
        DESCRIBE

        produces "application/json"

        response(200, "successful") do
          schema type: :array,
                 items: { "$ref": "#/components/schemas/BillboardCampaign" }
          let(:"api-key") { api_secret.secret }

          before { existing_campaign }

          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples
          run_test!
        end
      end
    end

    describe "POST /billboard_campaigns" do
      post("Create a billboard campaign") do
        tags "billboard_campaigns"
        description(<<-DESCRIBE.strip)
        Create a billboard campaign to group billboards under shared delivery caps, an optional end date,
        and an automated `ideal_daily_impressions` titration target.
        DESCRIBE

        produces "application/json"
        consumes "application/json"
        parameter name: :billboard_campaign, in: :body,
                  description: "Billboard campaign parameters.",
                  schema: { "$ref": "#/components/schemas/BillboardCampaign" }

        let(:billboard_campaign) do
          {
            name: "Developer Summit",
            max_impressions_count: 100_000,
            max_clicks_count: 2_000,
            ideal_daily_impressions: 10_000
          }
        end

        response "201", "A billboard campaign" do
          schema "$ref": "#/components/schemas/BillboardCampaign"
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples
          run_test!
        end

        response "422", "unprocessable" do
          let(:"api-key") { api_secret.secret }
          let(:billboard_campaign) { { max_impressions_count: 1_000 } }
          add_examples
          run_test!
        end
      end
    end
  end

  path "/api/billboard_campaigns/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "The ID of the billboard campaign."

    describe "GET /billboard_campaigns/{id}" do
      get("A billboard campaign") do
        tags "billboard_campaigns"
        description("Retrieve a single billboard campaign by ID. Requires Billboard admin privileges.")
        produces "application/json"

        response "200", "successful" do
          schema "$ref": "#/components/schemas/BillboardCampaign"
          let(:"api-key") { api_secret.secret }
          let(:id) { existing_campaign.id }
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          let(:id) { existing_campaign.id }
          add_examples
          run_test!
        end

        response "404", "not found" do
          let(:"api-key") { api_secret.secret }
          let(:id) { 999_999 }
          add_examples
          run_test!
        end
      end
    end

    describe "PUT /billboard_campaigns/{id}" do
      put("Update a billboard campaign") do
        tags "billboard_campaigns"
        description(<<-DESCRIBE.strip)
        Update a billboard campaign's name, caps, end date, or `ideal_daily_impressions` titration target.
        Modifying a campaign that governs an approved or Event-owned billboard requires the `modify_approved`
        Billboard sub-permission.
        DESCRIBE

        produces "application/json"
        consumes "application/json"
        parameter name: :billboard_campaign, in: :body,
                  description: "Billboard campaign parameters.",
                  schema: { "$ref": "#/components/schemas/BillboardCampaign" }

        let(:id) { existing_campaign.id }
        let(:billboard_campaign) do
          {
            ideal_daily_impressions: 12_000,
            max_impressions_count: 80_000
          }
        end

        response "200", "successful" do
          schema "$ref": "#/components/schemas/BillboardCampaign"
          let(:"api-key") { api_secret.secret }
          add_examples
          run_test!
        end

        response "401", "unauthorized" do
          let(:"api-key") { "invalid" }
          add_examples
          run_test!
        end

        response "403", "missing sub-permissions" do
          let(:restricted_secret) { create(:api_secret) }
          let(:"api-key") { restricted_secret.secret }

          before do
            create(:billboard, approved: true, billboard_campaign: existing_campaign)
            restricted_secret.user.add_role(:single_resource_admin, Billboard)
            SubPermissions.update_grant(user: restricted_secret.user, resource_type: "Billboard",
                                        sub_permissions: SubPermissions.build(allow: []))
          end

          add_examples
          run_test!
        end
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
# rubocop:enable RSpec/VariableName
