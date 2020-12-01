Feature: `have_http_status` matcher

  The `have_http_status` matcher is used to specify that a response returns a
  desired status code. It accepts one argument in any of the following formats:

  * numeric code
  * status name as defined in `Rack::Utils::SYMBOL_TO_STATUS_CODE`
  * generic status type (`:success`, `:missing`, `:redirect`, or `:error`)

  The matcher works on any `response` object. It is available for use in
  [controller specs](../controller-specs), [request specs](../request-specs), and [feature specs](../feature-specs).

  Scenario: Checking a numeric status code
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationController, :type => :controller do

        controller do
          def index
            render :json => {}, :status => 209
          end
        end

        describe "GET #index" do
          it "returns a 209 custom status code" do
            get :index
            expect(response).to have_http_status(209)
          end
        end

      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Checking a symbolic status name
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationController, :type => :controller do

        controller do
          def index
            render :json => {}, :status => :see_other
          end
        end

        describe "GET #index" do
          it "returns a :see_other status code" do
            get :index
            expect(response).to have_http_status(:see_other)
          end
        end

      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Checking a symbolic generic status type
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationController, :type => :controller do

        controller do
          def index
            render :json => {}, :status => :bad_gateway
          end
        end

        describe "GET #index" do
          it "returns a some type of error status code" do
            get :index
            expect(response).to have_http_status(:error)
          end
        end

      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Using in a controller spec
    Given a file named "spec/controllers/gadgets_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe GadgetsController, :type => :controller do

        describe "GET #index" do
          it "returns a 200 OK status" do
            get :index
            expect(response).to have_http_status(:ok)
          end
        end

      end
      """
    When I run `rspec spec/controllers/gadgets_spec.rb`
    Then the examples should all pass

  Scenario: Using in a request spec
    Given a file named "spec/requests/gadgets/widget_management_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe "Widget management", :type => :request do

        it "creates a Widget and redirects to the Widget's page" do
          get "/widgets/new"
          expect(response).to have_http_status(:ok)

          post "/widgets", :params => { :widget => {:name => "My Widget"} }
          expect(response).to have_http_status(302)

          follow_redirect!

          expect(response).to have_http_status(:success)
        end

      end
      """
    When I run `rspec spec/requests`
    Then the examples should all pass

  @capybara
  Scenario: Using in a feature spec
    Given a file named "spec/features/widget_management_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.feature "Widget management", :type => :feature do

        scenario "User creates a new widget" do
          visit "/widgets/new"
          expect(page).to have_http_status(200)

          click_button "Create Widget"

          expect(page).to have_http_status(:success)
        end

      end
      """
    When I run `rspec spec/features/widget_management_spec.rb`
    Then the example should pass
