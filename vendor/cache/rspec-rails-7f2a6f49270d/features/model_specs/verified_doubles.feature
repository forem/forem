Feature: verified doubles

  By default rspec verified doubles dont support dynamic methods on
  `instance_double`. `rspec-rails` enabled this support for column
  methods through an extension.

  Scenario:
    Given a file named "spec/models/widget_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe Widget, :type => :model do
        it "has one after adding one" do
          instance_double("Widget", :name => "my name")
        end
      end
      """
    When I run `rspec spec/models/widget_spec.rb`
    Then the examples should all pass
