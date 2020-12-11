Feature: engine routes for controllers

  Controller specs can specify the routeset that will be used for the example
  group. This is most useful when testing Rails engines.

  Scenario: specify engine route
    Given a file named "spec/controllers/widgets_controller_spec.rb" with:
      """ruby
      require "rails_helper"

      # A very simple Rails engine
      module MyEngine
        class Engine < ::Rails::Engine
          isolate_namespace MyEngine
        end

        Engine.routes.draw do
          resources :widgets, :only => [:show] do
            get :random, :on => :collection
          end
        end

        class WidgetsController < ::ActionController::Base
          def random
            @random_widget = Widget.all.shuffle.first
            redirect_to widget_path(@random_widget)
          end

          def show
            @widget = Widget.find(params[:id])
            render :text => @widget.name
          end
        end
      end

      RSpec.describe MyEngine::WidgetsController, :type => :controller do
        routes { MyEngine::Engine.routes }

        it "redirects to a random widget" do
          widget1 = Widget.create!(:name => "Widget 1")
          widget2 = Widget.create!(:name => "Widget 2")

          get :random
          expect(response).to be_redirect
          expect(response).to redirect_to(assigns(:random_widget))
        end
      end
      """
    When I run `rspec spec`
    Then the examples should all pass
