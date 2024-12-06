module FieldTest
  class BaseController < ActionController::Base
    layout "field_test/application"

    protect_from_forgery with: :exception

    http_basic_authenticate_with name: ENV["FIELD_TEST_USERNAME"], password: ENV["FIELD_TEST_PASSWORD"] if ENV["FIELD_TEST_PASSWORD"]
  end
end
