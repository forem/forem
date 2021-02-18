Feature: request spec

  Request specs provide a thin wrapper around Rails' integration tests, and are
  designed to drive behavior through the full stack, including routing
  (provided by Rails) and without stubbing (that's up to you).

  Request specs are marked by `:type => :request` or if you have set
  `config.infer_spec_type_from_file_location!` by placing them in `spec/requests`.

  With request specs, you can:

  * specify a single request
  * specify multiple requests across multiple controllers
  * specify multiple requests across multiple sessions

  Check the rails documentation on integration tests for more information.

  RSpec provides two matchers that delegate to Rails assertions:

      render_template # delegates to assert_template
      redirect_to     # delegates to assert_redirected_to

  Check the Rails docs for details on these methods as well.

  [Capybara](https://github.com/teamcapybara/capybara) is not supported in
  request specs. The recommended way to use Capybara is with
  [feature specs](../feature-specs/feature-spec).

  Scenario: specify managing a Widget with Rails integration methods
    Given a file named "spec/requests/widget_management_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "Widget management", :type => :request do

        it "creates a Widget and redirects to the Widget's page" do
          get "/widgets/new"
          expect(response).to render_template(:new)

          post "/widgets", :params => { :widget => {:name => "My Widget"} }

          expect(response).to redirect_to(assigns(:widget))
          follow_redirect!

          expect(response).to render_template(:show)
          expect(response.body).to include("Widget was successfully created.")
        end

        it "does not render a different template" do
          get "/widgets/new"
          expect(response).to_not render_template(:show)
        end
      end
      """
    When I run `rspec spec/requests/widget_management_spec.rb`
    Then the example should pass

  @rails_pre_6
  Scenario: requesting a JSON response
    Given a file named "spec/requests/widget_management_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "Widget management", :type => :request do

        it "creates a Widget" do
          headers = { "ACCEPT" => "application/json" }
          post "/widgets", :params => { :widget => {:name => "My Widget"} }, :headers => headers

          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:created)
        end

      end
      """
    When I run `rspec spec/requests/widget_management_spec.rb`
    Then the example should pass

  @rails_post_6
  Scenario: requesting a JSON response
    Given a file named "spec/requests/widget_management_spec.rb" with:
    """ruby
    require "rails_helper"

    RSpec.describe "Widget management", :type => :request do
      it "creates a Widget" do
        headers = { "ACCEPT" => "application/json" }
        post "/widgets", :params => { :widget => {:name => "My Widget"} }, :headers => headers

        expect(response.content_type).to eq("application/json; charset=utf-8")
        expect(response).to have_http_status(:created)
      end
    end
    """
    When I run `rspec spec/requests/widget_management_spec.rb`
    Then the example should pass

  Scenario: providing JSON data
    Given a file named "spec/requests/widget_management_spec.rb" with:
    """ruby
    require "rails_helper"

    RSpec.describe "Widget management", :type => :request do

      it "creates a Widget and redirects to the Widget's page" do
        headers = { "CONTENT_TYPE" => "application/json" }
        post "/widgets", :params => '{ "widget": { "name":"My Widget" } }', :headers => headers
        expect(response).to redirect_to(assigns(:widget))
      end

    end
    """
    When I run `rspec spec/requests/widget_management_spec.rb`
    Then the example should pass

  Scenario: using engine route helpers
    Given a file named "spec/requests/widgets_spec.rb" with:
      """ruby
      require "rails_helper"

      # A very simple Rails engine
      module MyEngine
        class Engine < ::Rails::Engine
          isolate_namespace MyEngine
        end

        class LinksController < ::ActionController::Base
          def index
            render plain: 'hit_engine_route'
          end
        end
      end

      MyEngine::Engine.routes.draw do
        resources :links, :only => [:index]
      end

      Rails.application.routes.draw do
        mount MyEngine::Engine => "/my_engine"
      end

      module MyEngine
        RSpec.describe "Links", :type => :request do
          include Engine.routes.url_helpers

          it "redirects to a random widget" do
            get links_url
            expect(response.body).to eq('hit_engine_route')
          end
        end
      end
      """
    When I run `rspec spec`
    Then the example should pass
