require "rails/generators"

module Ahoy
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def copy_templates
        activerecord = defined?(ActiveRecord)
        mongoid = defined?(Mongoid)

        selection =
          if activerecord && mongoid
            puts <<-MSG

Which data store would you like to use?
 1. ActiveRecord (default)
 2. Mongoid
 3. Neither
            MSG

            ask(">")
          elsif activerecord
            "1"
          elsif mongoid
            "2"
          else
            "3"
          end

        case selection
        when "", "1"
          invoke "ahoy:activerecord"
        when "2"
          invoke "ahoy:mongoid"
        when "3"
          invoke "ahoy:base"
        else
          abort "Error: must enter a number [1-3]"
        end
      end
    end
  end
end
