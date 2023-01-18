require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName

RSpec.describe "api/v1/pages" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  let(:api_secret) { create(:api_secret) }
  let(:page) { create(:page) }
  let(:user) { api_secret.user }

  before do
    user.add_role(:admin)

    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
  end

  path "/api/pages" do
    describe "get to view all pages" do
      get("show details for all pages") do
        security []
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve details for all Page objects.
        DESCRIBE

        produces "application/json"

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end
      end
    end
  end

  path "/api/pages/{id}" do
    describe "get to view a page" do
      get("show details for a page") do
        security []
        tags "pages"
        description(<<-DESCRIBE.strip)
        This endpoint allows the client to retrieve details for a single Page object, specified by ID.
        DESCRIBE

        produces "application/json"
        parameter name: :id, in: :path, required: true,
                  description: "The ID of the page.",
                  schema: {
                    type: :integer,
                    format: :int32,
                    minimum: 1
                  },
                  example: 1

        let(:id) { page.id }

        response(200, "successful") do
          let(:"api-key") { api_secret.secret }
          add_examples

          run_test!
        end
      end
    end
  end
end

# rubocop:enable RSpec/VariableName
# rubocop:enable RSpec/EmptyExampleGroup
