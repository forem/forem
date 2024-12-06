require "rails/generators"

module Ahoy
  module Generators
    module Messages
      class MongoidGenerator < Rails::Generators::Base
        source_root File.join(__dir__, "templates")

        class_option :encryption, type: :string
        # deprecated
        class_option :unencrypted, type: :boolean

        def copy_templates
          case encryption
          when "lockbox"
            template "mongoid_lockbox.rb", "app/models/ahoy/message.rb", lockbox_method: lockbox_method
          else
            template "mongoid.rb", "app/models/ahoy/message.rb"
          end
        end

        # TODO remove default
        def encryption
          case options[:encryption]
          when "lockbox", "none"
            options[:encryption]
          when nil
            if options[:unencrypted]
              # TODO deprecation warning
              "none"
            else
              "lockbox"
            end
          else
            abort "Error: encryption must be lockbox or none"
          end
        end

        def lockbox_method
          if defined?(Lockbox::VERSION) && Lockbox::VERSION.to_i < 1
            "encrypts"
          else
            "has_encrypted"
          end
        end
      end
    end
  end
end
