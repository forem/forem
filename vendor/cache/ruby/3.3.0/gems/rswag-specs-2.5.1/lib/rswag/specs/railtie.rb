# frozen_string_literal: true

module Rswag
  module Specs
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load File.expand_path('../../tasks/rswag-specs_tasks.rake', __dir__)
      end

      generators do
        require 'generators/rspec/swagger_generator.rb'
      end
    end
  end
end
