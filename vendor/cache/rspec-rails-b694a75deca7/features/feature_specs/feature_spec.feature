Feature: Feature spec

  Feature specs are high-level tests meant to exercise slices of functionality
  through an application. They should drive the application only via its external
  interface, usually web pages.

  Feature specs are marked by `:type => :feature` or if you have set
  `config.infer_spec_type_from_file_location!` by placing them in
  `spec/features`.

  Feature specs require the [Capybara](https://github.com/teamcapybara/capybara) gem, version 2.13.0 or later.
  Refer to the [capybara API documentation](https://rubydoc.info/github/teamcapybara/capybara/master) for more information on the methods and matchers that can be
  used in feature specs. Capybara is intended to simulate browser requests with HTTP. It will primarily send HTML content.

  The `feature` and `scenario` DSL correspond to `describe` and `it`, respectively.
  These methods are simply aliases that allow feature specs to read more as
  [customer](http://c2.com/cgi/wiki?CustomerTest) and [acceptance](http://c2.com/cgi/wiki?AcceptanceTest) tests. When capybara is required it sets
  `:type => :feature` automatically for you.

  @rails_pre_5.1
  Scenario: Feature specs are skipped without Capybara
    Given a file named "spec/features/widget_management_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.feature "Widget management", :type => :feature do
        scenario "User creates a new widget" do
          visit "/widgets/new"

          fill_in "Name", :with => "My Widget"
          click_button "Create Widget"

          expect(page).to have_text("Widget was successfully created.")
        end
      end
      """
    When I run `rspec spec/features/widget_management_spec.rb`
    Then the exit status should be 0
    And the output should contain "1 example, 0 failures, 1 pending"
    And the output should contain:
      """
      Pending: (Failures listed here are expected and do not affect your suite's status)

        1) Widget management User creates a new widget
           # Feature specs require the Capybara (https://github.com/teamcapybara/capybara) gem, version 2.13.0 or later.
           # ./spec/features/widget_management_spec.rb:4
      """

  @capybara
  Scenario: specify creating a Widget by driving the application with capybara
    Given a file named "spec/features/widget_management_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.feature "Widget management", :type => :feature do
        scenario "User creates a new widget" do
          visit "/widgets/new"

          click_button "Create Widget"

          expect(page).to have_text("Widget was successfully created.")
        end
      end
      """
    When I run `rspec spec/features/widget_management_spec.rb`
    Then the example should pass
