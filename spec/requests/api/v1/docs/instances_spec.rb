require "rails_helper"
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup
# rubocop:disable RSpec/VariableName
# rubocop:disable Layout/LineLength

RSpec.describe "Api::V1::Docs::Instances" do
  let(:Accept) { "application/vnd.forem.api-v1+json" }

  describe "GET /instance" do
    path "/api/instance" do
      get "Retrieve instance configuration details" do
        tags "instance"
        security []
        produces "application/json"

        response "200", "successful" do
          # Stub to avoid missing .release-version file error in some environments
          before do
            allow(Rails.root.join(".release-version")).to receive(:read).and_return("v1.0.0")
          end

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
