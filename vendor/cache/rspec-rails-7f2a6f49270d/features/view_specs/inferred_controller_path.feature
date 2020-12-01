Feature: view spec infers controller path and action

  Scenario: infer controller path
    Given a file named "spec/views/widgets/new.html.erb_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "widgets/new" do
        it "infers the controller path" do
          expect(controller.request.path_parameters[:controller]).to eq("widgets")
          expect(controller.controller_path).to eq("widgets")
        end
      end
      """
    When I run `rspec spec/views`
    Then the examples should all pass

  Scenario: infer action
    Given a file named "spec/views/widgets/new.html.erb_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "widgets/new" do
        it "infers the controller action" do
          expect(controller.request.path_parameters[:action]).to eq("new")
        end
      end
      """
    When I run `rspec spec/views`
    Then the examples should all pass

  Scenario: do not infer action in a partial
    Given a file named "spec/views/widgets/_form.html.erb_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "widgets/_form" do
        it "includes a link to new" do
          expect(controller.request.path_parameters[:action]).to be_nil
        end
      end
      """
    When I run `rspec spec/views`
    Then the examples should all pass

