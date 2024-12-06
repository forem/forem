# frozen_string_literal: true

require 'rails/generators'

module Rswag
  module Specs
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def add_swagger_helper
        template('swagger_helper.rb', 'spec/swagger_helper.rb')
      end
    end
  end
end
