Feature: helper spec

  Helper specs are marked by `:type => :helper` or if you have set
  `config.infer_spec_type_from_file_location!` by placing them in `spec/helpers`.

  Helper specs expose a `helper` object, which includes the helper module being
  specified, the `ApplicationHelper` module (if there is one) and all of the
  helpers built into Rails. It does not include the other helper modules in
  your app.

  To access the helper methods you're specifying, simply call them directly
  on the `helper` object.

  NOTE: helper methods defined in controllers are not included.

  Scenario: helper method that returns a value
    Given a file named "spec/helpers/application_helper_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationHelper, :type => :helper do
        describe "#page_title" do
          it "returns the default title" do
            expect(helper.page_title).to eq("RSpec is your friend")
          end
        end
      end
      """
    And a file named "app/helpers/application_helper.rb" with:
      """ruby
      module ApplicationHelper
        def page_title
          "RSpec is your friend"
        end
      end
      """
    When I run `rspec spec/helpers/application_helper_spec.rb`
    Then the examples should all pass

  Scenario: helper method that accesses an instance variable
    Given a file named "spec/helpers/application_helper_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationHelper, :type => :helper do
        describe "#page_title" do
          it "returns the instance variable" do
            assign(:title, "My Title")
            expect(helper.page_title).to eql("My Title")
          end
        end
      end
      """
    And a file named "app/helpers/application_helper.rb" with:
      """ruby
      module ApplicationHelper
        def page_title
          @title || nil
        end
      end
      """
    When I run `rspec spec/helpers/application_helper_spec.rb`
    Then the examples should all pass

  Scenario: application helper is included in helper object
    Given a file named "spec/helpers/widgets_helper_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe WidgetsHelper, :type => :helper do
        describe "#widget_title" do
          it "includes the app name" do
            assign(:title, "This Widget")
            expect(helper.widget_title).to eq("The App: This Widget")
          end
        end
      end
      """
    And a file named "app/helpers/application_helper.rb" with:
      """ruby
      module ApplicationHelper
        def app_name
          "The App"
        end
      end
      """
    And a file named "app/helpers/widgets_helper.rb" with:
      """ruby
      module WidgetsHelper
        def widget_title
          "#{app_name}: #{@title}"
        end
      end
      """
    When I run `rspec spec/helpers/widgets_helper_spec.rb`
    Then the examples should all pass

  Scenario: url helpers are defined
    Given a file named "spec/helpers/widgets_helper_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe WidgetsHelper, :type => :helper do
        describe "#link_to_widget" do
          it "links to a widget using its name" do
            widget = Widget.create!(:name => "This Widget")
            expect(helper.link_to_widget(widget)).to include("This Widget")
            expect(helper.link_to_widget(widget)).to include(widget_path(widget))
          end
        end
      end
      """
    And a file named "app/helpers/widgets_helper.rb" with:
      """ruby
      module WidgetsHelper
        def link_to_widget(widget)
          link_to(widget.name, widget_path(widget))
        end
      end
      """
    When I run `rspec spec/helpers/widgets_helper_spec.rb`
    Then the examples should all pass
