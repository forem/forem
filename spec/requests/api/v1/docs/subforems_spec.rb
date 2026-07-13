require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Subforems" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }
  before do
    create(:subforem, discoverable: true)
  end

  describe "GET /subforems" do
    path "/api/subforems" do
      get "Retrieve all discoverable subforems" do
        tags "subforems"
        security []
        produces "application/json"

        response "200", "successful" do
          schema type: :array, items: { "$ref": "#/components/schemas/Subforem" }
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
