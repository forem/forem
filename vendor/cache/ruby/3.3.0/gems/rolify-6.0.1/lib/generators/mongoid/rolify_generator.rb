require 'rails/generators/mongoid_generator'
require 'active_support/core_ext'

module Mongoid
  module Generators
    class RolifyGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      argument :user_cname, :type => :string, :default => "User", :banner => "User"

      def generate_model
        invoke "mongoid:model", [ name ]
      end

      def inject_role_class
        inject_into_file(model_path, model_contents, :after => "include Mongoid::Document\n")
      end

      def user_reference
        user_cname.demodulize.underscore
      end

      def role_reference
        class_name.demodulize.underscore
      end

      def model_path
        File.join("app", "models", "#{file_path}.rb")
      end

      def model_contents
        content = <<RUBY
  has_and_belongs_to_many :%{user_cname}
  belongs_to :resource, :polymorphic => true

  field :name, :type => String

  index({
    :name => 1,
    :resource_type => 1,
    :resource_id => 1
  },
  { :unique => true})

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify
RUBY
        content % { :user_cname => user_cname.constantize.collection_name }
      end
    end
  end
end
