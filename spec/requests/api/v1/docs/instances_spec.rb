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
        description "Retrieve configuration details for the current Forem instance.

### Instance Metadata:
- Bypasses authentication.
- Returns public Forem version, branding parameters, community guidelines references, and supported features configurations."
        security []
        produces "application/json"

        response "200", "successful" do
          before do
            allow(Rails.root).to receive(:join).and_call_original
            allow(Rails.root).to receive(:join).with(".release-version").and_return(instance_double(Pathname, read: "v1.0.0"))
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
