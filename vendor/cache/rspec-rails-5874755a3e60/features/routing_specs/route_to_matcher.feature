Feature: route_to matcher

  The `route_to` matcher specifies that a request (verb + path) is routable.
  It is most valuable when specifying routes other than standard RESTful
  routes.

      expect(get("/")).to route_to("welcome#index") # new in 2.6.0

      or

      expect(:get => "/").to route_to(:controller => "welcome")

  Scenario: passing route spec with shortcut syntax
    Given a file named "spec/routing/widgets_routing_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "routes for Widgets", :type => :routing do
        it "routes /widgets to the widgets controller" do
          expect(get("/widgets")).
            to route_to("widgets#index")
        end
      end
      """

    When I run `rspec spec/routing/widgets_routing_spec.rb`
    Then the examples should all pass

  Scenario: passing route spec with verbose syntax
    Given a file named "spec/routing/widgets_routing_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "routes for Widgets", :type => :routing do
        it "routes /widgets to the widgets controller" do
          expect(:get => "/widgets").
            to route_to(:controller => "widgets", :action => "index")
        end
      end
      """

    When I run `rspec spec/routing/widgets_routing_spec.rb`
    Then the examples should all pass

  Scenario: route spec for a route that doesn't exist (fails)
    Given a file named "spec/routing/widgets_routing_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "routes for Widgets", :type => :routing do
        it "routes /widgets/foo to the /foo action" do
          expect(get("/widgets/foo")).to route_to("widgets#foo")
        end
      end
      """

    When I run `rspec spec/routing/widgets_routing_spec.rb`
    Then the output should contain "1 failure"

  Scenario: route spec for a namespaced route with shortcut specifier
    Given a file named "spec/routing/admin_routing_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "routes for Widgets", :type => :routing do
        it "routes /admin/accounts to the admin/accounts controller" do
          expect(get("/admin/accounts")).
            to route_to("admin/accounts#index")
        end
      end
      """

    When I run `rspec spec/routing/admin_routing_spec.rb`
    Then the examples should all pass

  Scenario: route spec for a namespaced route with verbose specifier
   Given a file named "spec/routing/admin_routing_spec.rb" with:
     """ruby
     require "rails_helper"

     RSpec.describe "routes for Widgets", :type => :routing do
       it "routes /admin/accounts to the admin/accounts controller" do
         expect(get("/admin/accounts")).
           to route_to(:controller => "admin/accounts", :action => "index")
       end
     end
     """

   When I run `rspec spec/routing/admin_routing_spec.rb`
   Then the examples should all pass
