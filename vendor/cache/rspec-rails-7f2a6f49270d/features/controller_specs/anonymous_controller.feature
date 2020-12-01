Feature: anonymous controller

  Use the `controller` method to define an anonymous controller that will
  inherit from the described class. This is useful for specifying behavior like
  global error handling.

  To specify a different base class you can pass the class explicitly to the
  controller method:

  ```ruby
  controller(BaseController)
  ```

  You can also disable base type inference, in which case anonymous controllers
  will inherit from `ApplicationController` instead of the described class by
  default:

  ```ruby
  RSpec.configure do |c|
    c.infer_base_class_for_anonymous_controllers = false
  end

  RSpec.describe BaseController, :type => :controller do
    controller do
      def index; end

      ​# this normally creates an anonymous `BaseController` subclass,
      ​# however since `infer_base_class_for_anonymous_controllers` is
      ​# disabled, it creates a subclass of `ApplicationController`
    end
  end
  ```

  Scenario: Specify error handling in `ApplicationController` with redirect
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base
        class AccessDenied < StandardError; end

        rescue_from AccessDenied, :with => :access_denied

      private

        def access_denied
          redirect_to "/401.html"
        end
      end

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def index
            raise ApplicationController::AccessDenied
          end
        end

        describe "handling AccessDenied exceptions" do
          it "redirects to the /401.html page" do
            get :index
            expect(response).to redirect_to("/401.html")
          end
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Specify error handling in `ApplicationController` with render
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base
        class AccessDenied < StandardError; end

        rescue_from AccessDenied, :with => :access_denied

      private

        def access_denied
          render "errors/401"
        end
      end

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def index
            raise ApplicationController::AccessDenied
          end
        end

        describe "handling AccessDenied exceptions" do
          it "renders the errors/401 template" do
            get :index
            expect(response).to render_template("errors/401")
          end
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  # Deprecated support removed in https://github.com/rails/rails/commit/d52d7739468153bd6cb7c629f60bd5cd7ebea3eb
  @rails_pre_6
  Scenario: Specify error handling in `ApplicationController` with render :file
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base
        class AccessDenied < StandardError; end

        rescue_from AccessDenied, :with => :access_denied

      private

        def access_denied
          render :file => "errors/401"
        end
      end

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def index
            raise ApplicationController::AccessDenied
          end
        end

        describe "handling AccessDenied exceptions" do
          it "renders the errors/401 template" do
            get :index
            expect(response).to render_template("errors/401")
          end
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Specify error handling in a subclass
    Given a file named "spec/controllers/application_controller_subclass_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base
        class AccessDenied < StandardError; end
      end

      class FoosController < ApplicationController

        rescue_from ApplicationController::AccessDenied,
                    :with => :access_denied

      private

        def access_denied
          redirect_to "/401.html"
        end
      end

      RSpec.describe FoosController, :type => :controller do
        controller(FoosController) do
          def index
            raise ApplicationController::AccessDenied
          end
        end

        describe "handling AccessDenied exceptions" do
          it "redirects to the /401.html page" do
            get :index
            expect(response).to redirect_to("/401.html")
          end
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Infer base class from the described class
    Given a file named "spec/controllers/base_class_can_be_inferred_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base; end

      class FoosController < ApplicationController; end

      RSpec.describe FoosController, :type => :controller do
        controller do
          def index
            render :plain => "Hello World"
          end
        end

        it "creates anonymous controller derived from FoosController" do
          expect(controller).to be_a_kind_of(FoosController)
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Use `name` and `controller_name` from the described class
    Given a file named "spec/controllers/get_name_and_controller_name_from_described_class_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base; end
      class FoosController < ApplicationController; end

      RSpec.describe "Access controller names", :type => :controller do
        controller FoosController do
          def index
            @name = self.class.name
            @controller_name = controller_name
            render :plain => "Hello World"
          end
        end

        before do
          get :index
        end

        it "gets the class name as described" do
          expect(assigns[:name]).to eq('FoosController')
        end

        it "gets the controller_name as described" do
          expect(assigns[:controller_name]).to eq('foos')
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Invoke `around_filter` and `around_action` in base class
    Given a file named "spec/controllers/application_controller_around_filter_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base
        around_action :an_around_filter

        def an_around_filter
          @callback_invoked = true
          yield
        end
      end

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def index
            render :plain => ""
          end
        end

        it "invokes the callback" do
          get :index

          expect(assigns[:callback_invoked]).to be_truthy
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Anonymous controllers only create resource routes
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      if defined?(ActionController::UrlGenerationError)
        ExpectedRoutingError = ActionController::UrlGenerationError
      else
        ExpectedRoutingError = ActionController::RoutingError
      end

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def index
            render :plain => "index called"
          end

          def create
            render :plain => "create called"
          end

          def new
            render :plain => "new called"
          end

          def show
            render :plain => "show called"
          end

          def edit
            render :plain => "edit called"
          end

          def update
            render :plain => "update called"
          end

          def destroy
            render :plain => "destroy called"
          end

          def willerror
            render :plain => "will not render"
          end
        end

        describe "#index" do
          it "responds to GET" do
            get :index
            expect(response.body).to eq "index called"
          end

          it "also responds to POST" do
            post :index
            expect(response.body).to eq "index called"
          end

          it "also responds to PUT" do
            put :index
            expect(response.body).to eq "index called"
          end

          it "also responds to DELETE" do
            delete :index
            expect(response.body).to eq "index called"
          end
        end

        describe "#create" do
          it "responds to POST" do
            post :create
            expect(response.body).to eq "create called"
          end

          # And the rest...
          %w{get post put delete}.each do |calltype|
            it "responds to #{calltype}" do
              send(calltype, :create)
              expect(response.body).to eq "create called"
            end
          end
        end

        describe "#new" do
          it "responds to GET" do
            get :new
            expect(response.body).to eq "new called"
          end

          # And the rest...
          %w{get post put delete}.each do |calltype|
            it "responds to #{calltype}" do
              send(calltype, :new)
              expect(response.body).to eq "new called"
            end
          end
        end

        describe "#edit" do
          it "responds to GET" do
            get :edit, :params => { :id => "anyid" }
            expect(response.body).to eq "edit called"
          end

          it "requires the :id parameter" do
            expect { get :edit }.to raise_error(ExpectedRoutingError)
          end

          # And the rest...
          %w{get post put delete}.each do |calltype|
            it "responds to #{calltype}" do
              send(calltype, :edit, :params => {:id => "anyid"})
              expect(response.body).to eq "edit called"
            end
          end
        end

        describe "#show" do
          it "responds to GET" do
            get :show, :params => { :id => "anyid" }
            expect(response.body).to eq "show called"
          end

          it "requires the :id parameter" do
            expect { get :show }.to raise_error(ExpectedRoutingError)
          end

          # And the rest...
          %w{get post put delete}.each do |calltype|
            it "responds to #{calltype}" do
              send(calltype, :show, :params => {:id => "anyid"})
              expect(response.body).to eq "show called"
            end
          end
        end

        describe "#update" do
          it "responds to PUT" do
            put :update, :params => { :id => "anyid" }
            expect(response.body).to eq "update called"
          end

          it "requires the :id parameter" do
            expect { put :update }.to raise_error(ExpectedRoutingError)
          end

          # And the rest...
          %w{get post put delete}.each do |calltype|
            it "responds to #{calltype}" do
              send(calltype, :update, :params =>  {:id => "anyid"})
              expect(response.body).to eq "update called"
            end
          end
        end

        describe "#destroy" do
          it "responds to DELETE" do
            delete :destroy, :params => { :id => "anyid" }
            expect(response.body).to eq "destroy called"
          end

          it "requires the :id parameter" do
            expect { delete :destroy }.to raise_error(ExpectedRoutingError)
          end

          # And the rest...
          %w{get post put delete}.each do |calltype|
            it "responds to #{calltype}" do
              send(calltype, :destroy, :params => {:id => "anyid"})
              expect(response.body).to eq "destroy called"
            end
          end
        end

        describe "#willerror" do
          it "cannot be called" do
            expect { get :willerror }.to raise_error(ExpectedRoutingError)
          end
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Draw custom routes for anonymous controllers
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def custom
            render :plain => "custom called"
          end
        end

        specify "manually draw the route to request a custom action" do
          routes.draw { get "custom" => "anonymous#custom" }

          get :custom
          expect(response.body).to eq "custom called"
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Draw custom routes for anonymous controllers which don't inherit from application controller
    Given a file named "spec/controllers/other_controller_spec.rb" with:
      """ruby
      require "rails_helper"
      class OtherController < ActionController::Base
      end

      RSpec.describe OtherController, :type => :controller do
        controller do
          def custom
            render :plain => "custom called"
          end
        end

        specify "manually draw the route to request a custom action" do
          routes.draw { get "custom" => "other#custom" }

          get :custom
          expect(response.body).to eq "custom called"
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Draw custom routes for defined controllers
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      class FoosController < ApplicationController; end

      RSpec.describe ApplicationController, :type => :controller do
        controller FoosController do
          def custom
            render :plain => "custom called"
          end
        end

        specify "manually draw the route to request a custom action" do
          routes.draw { get "custom" => "foos#custom" }

          get :custom
          expect(response.body).to eq "custom called"
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass

  Scenario: Works with namespaced controllers
    Given a file named "spec/controllers/namespaced_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      class ApplicationController < ActionController::Base; end

      module Outer
        module Inner
          class FoosController < ApplicationController; end
        end
      end

      RSpec.describe Outer::Inner::FoosController, :type => :controller do
        controller do
          def index
            @name = self.class.name
            @controller_name = controller_name
            render :plain => "Hello World"
          end
        end

        it "creates anonymous controller derived from the namespace" do
          expect(controller).to be_a_kind_of(Outer::Inner::FoosController)
        end

        it "gets the class name as described" do
          expect{ get :index }.to change{
            assigns[:name]
          }.to eq('Outer::Inner::FoosController')
        end

        it "gets the controller_name as described" do
          expect{ get :index }.to change{
            assigns[:controller_name]
          }.to eq('foos')
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass
  Scenario: Refer to application routes in the controller under test
    Given a file named "spec/controllers/application_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      Rails.application.routes.draw do
        match "/login" => "sessions#new", :as => "login", :via => "get"
      end

      RSpec.describe ApplicationController, :type => :controller do
        controller do
          def index
            redirect_to login_url
          end
        end

        it "redirects to the login page" do
          get :index
          expect(response).to redirect_to("/login")
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass
