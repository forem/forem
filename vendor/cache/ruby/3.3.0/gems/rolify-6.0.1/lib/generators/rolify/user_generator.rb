require 'rails/generators/migration'
require 'active_support/core_ext'

module Rolify
  module Generators
    class UserGenerator < Rails::Generators::NamedBase
      argument :role_cname, :type => :string, :default => "Role"
      class_option :orm, :type => :string, :default => "active_record"
      
      desc "Inject rolify method in the User class."

      def inject_user_content
        inject_into_file(model_path, :after => inject_rolify_method) do
          "  rolify#{role_association}\n"
        end
      end
      
      def inject_rolify_method
        if options.orm == :active_record
          /class #{class_name.camelize}\n|class #{class_name.camelize} .*\n|class #{class_name.demodulize.camelize}\n|class #{class_name.demodulize.camelize} .*\n/
        else
          /include Mongoid::Document\n|include Mongoid::Document .*\n/
        end
      end
      
      def model_path
        File.join("app", "models", "#{file_path}.rb")
      end
      
      def role_association
        if role_cname != "Role"
          " :role_cname => '#{role_cname.camelize}'"
        else
          ""
        end
      end
    end
  end
end
