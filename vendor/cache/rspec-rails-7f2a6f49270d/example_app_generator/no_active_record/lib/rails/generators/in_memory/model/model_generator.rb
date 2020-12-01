# Hook into the work already done to support older Rails
require 'generators/rspec'

module InMemory
  module Generators
    class ModelGenerator < ::Rspec::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Creates a Fake ActiveRecord acting model"
      argument :attributes,
               type: :array,
               default: [],
               banner: "field:type field:type"

      check_class_collision

      class_option :parent,
                   type: :string,
                   desc: "The parent class for the generated model"

      def create_model_file
        template "model.rb.erb",
                 File.join("app/models", class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
