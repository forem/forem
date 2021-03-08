require 'rails_helper'

RSpec.describe "Fixture warnings" do
  def generate_fixture_example_group(hook_type)
    RSpec.describe do
      include RSpec::Rails::RailsExampleGroup
      fixtures :things

      before(hook_type) do
        things :a
      end

      it "" do

      end
    end
  end

  it "Warns when a fixture call is made in a before :context call" do
    expect(RSpec).to receive(:warn_with).with(match(/Calling fixture method in before :context/))

    generate_fixture_example_group(:context).run
  end

  it "Does not warn when a fixture call is made in a before :each call" do
    expect(RSpec).not_to receive(:warn_with)

    generate_fixture_example_group(:each).run
  end

end

RSpec.describe "Global fixture warnings" do
  def generate_fixture_example_group(hook_type)
    RSpec.describe do
      include RSpec::Rails::RailsExampleGroup

      before(hook_type) do
        things :a
      end

      it "" do

      end
    end
  end
  around do |ex|
    RSpec.configuration.global_fixtures = [:things]
    ex.call
    RSpec.configuration.global_fixtures = []
  end

  it "warns when a global fixture call is made in a before :context call" do
    expect(RSpec).to receive(:warn_with).with(match(/Calling fixture method in before :context/))

    generate_fixture_example_group(:context).run
  end

  it "does not warn when a global fixture call is made in a before :each call" do
    expect(RSpec).not_to receive(:warn_with)

    generate_fixture_example_group(:each).run
  end
end
