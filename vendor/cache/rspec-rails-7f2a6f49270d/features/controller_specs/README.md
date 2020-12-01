Controller specs are marked by `:type => :controller` or if you have set
`config.infer_spec_type_from_file_location!` by placing them in `spec/controllers`.

A controller spec is an RSpec wrapper for a Rails functional test
([ActionController::TestCase::Behavior](https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/test_case.rb)).
It allows you to simulate a single http request in each example, and then
specify expected outcomes such as:

* rendered templates
* redirects
* instance variables assigned in the controller to be shared with the view
* cookies sent back with the response

To specify outcomes, you can use:

- standard rspec matchers (`expect(response.status).to eq(200)`)
- standard test/unit assertions (`assert_equal 200, response.status`)
- rails assertions (`assert_response 200`)
- rails-specific matchers:
  - [`render_template`](matchers/render-template-matcher)

    ```ruby
    expect(response).to render_template(:new)   # wraps assert_template
    ```
  - [`redirect_to`](matchers/redirect-to-matcher)

    ```ruby
    expect(response).to redirect_to(location)   # wraps assert_redirected_to
    ```
  - [`have_http_status`](matchers/have-http-status-matcher)

    ```ruby
    expect(response).to have_http_status(:created)
    ```
  - [`be_a_new`](matchers/be-a-new-matcher)

    ```ruby
    expect(assigns(:widget)).to be_a_new(Widget)
    ```

## Examples

    RSpec.describe TeamsController do
      describe "GET index" do
        it "assigns @teams" do
          team = Team.create
          get :index
          expect(assigns(:teams)).to eq([team])
        end

        it "renders the index template" do
          get :index
          expect(response).to render_template("index")
        end
      end
    end

## Views

* by default, views are not rendered. See
  [views are stubbed by default](controller-specs/views-are-stubbed-by-default) and
  [render_views](controller-specs/render-views) for details.

## Headers

We encourage you to use [request specs](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec) if you want to set headers in your call. If you still want to use controller specs with custom http headers you can use `request.headers`:

    require "rails_helper"

    RSpec.describe TeamsController, type: :controller do
      describe "GET index" do
        it "returns a 200" do
          request.headers["Authorization"] = "foo"
          get :show
          expect(response).to have_http_status(:ok)
        end
      end
    end
