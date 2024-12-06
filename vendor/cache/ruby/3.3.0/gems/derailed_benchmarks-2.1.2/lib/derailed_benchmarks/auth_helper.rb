# frozen_string_literal: true

require 'securerandom'

module DerailedBenchmarks
  # Base helper class. Can be used to authenticate different strategies
  # The root app will be wrapped by an authentication action
  class AuthHelper
    attr_reader   :app

    # Put any coded needed to set up or initialize your authentication module here
    def setup
      raise "Must subclass"
    end

    # Gets called for every request. Place all auth logic here.
    # Return value is expected to be an valid Rack response array.
    # If you do not manually `app.call(env)` here, the client app
    # will never be called.
    def call(env)
      raise "Must subclass"
    end

    # Returns self and sets the target app
    def add_app(app)
      raise "App is required argument" unless app
      @app = app
      setup
      self
    end
  end
end

require 'derailed_benchmarks/auth_helpers/devise'
