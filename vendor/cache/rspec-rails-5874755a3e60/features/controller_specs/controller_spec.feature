Feature: controller spec

  Scenario: simple passing example
    Given a file named "spec/controllers/widgets_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe WidgetsController, :type => :controller do
        describe "GET index" do
          it "has a 200 status code" do
            get :index
            expect(response.status).to eq(200)
          end
        end
      end
      """
    When I run `rspec spec`
    Then the example should pass

  Scenario: controller is exposed to global before hooks
    Given a file named "spec/controllers/widgets_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.configure {|c| c.before { expect(controller).not_to be_nil }}

      RSpec.describe WidgetsController, :type => :controller do
        describe "GET index" do
          it "doesn't matter" do
          end
        end
      end
      """
    When I run `rspec spec`
    Then the example should pass

  @rails_pre_6
  Scenario: setting a different content type for example json (request type)
    Given a file named "spec/controllers/widgets_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe WidgetsController, :type => :controller do
        describe "responds to" do
          it "responds to html by default" do
            post :create, :params => { :widget => { :name => "Any Name" } }
            expect(response.content_type).to eq "text/html"
          end

          it "responds to custom formats when provided in the params" do
            post :create, :params => { :widget => { :name => "Any Name" }, :format => :json }
            expect(response.content_type).to eq "application/json"
          end
        end
      end
      """
    When I run `rspec spec`
    Then the example should pass

  @rails_post_6
  Scenario: setting a different content type for example json (request type)
    Given a file named "spec/controllers/widgets_controller_spec.rb" with:
    """ruby
    require "rails_helper"

    RSpec.describe WidgetsController, :type => :controller do
      describe "responds to" do
        it "responds to html by default" do
          post :create, :params => { :widget => { :name => "Any Name" } }
          expect(response.content_type).to eq "text/html; charset=utf-8"
        end

        it "responds to custom formats when provided in the params" do
          post :create, :params => { :widget => { :name => "Any Name" }, :format => :json }
          expect(response.content_type).to eq "application/json; charset=utf-8"
        end
      end
    end
    """
    When I run `rspec spec`
    Then the example should pass

  @rails_post_6
  Scenario: setting a different media type for example json (request type)
    Given a file named "spec/controllers/widgets_controller_spec.rb" with:
    """ruby
    require "rails_helper"

    RSpec.describe WidgetsController, :type => :controller do
      describe "responds to" do
        it "responds to html by default" do
          post :create, :params => { :widget => { :name => "Any Name" } }
          expect(response.media_type).to eq "text/html"
        end

        it "responds to custom formats when provided in the params" do
          post :create, :params => { :widget => { :name => "Any Name" }, :format => :json }
          expect(response.media_type).to eq "application/json"
        end
      end
    end
    """
    When I run `rspec spec`
    Then the example should pass
