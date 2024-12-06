require "rails/generators/active_record"

module Ahoy
  module Generators
    module Messages
      class ActiverecordGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration
        source_root File.join(__dir__, "templates")

        class_option :encryption, type: :string
        # deprecated
        class_option :unencrypted, type: :boolean

        def copy_migration
          encryption # ensure valid
          migration_template "migration.rb", "db/migrate/create_ahoy_messages.rb", migration_version: migration_version
        end

        def copy_template
          case encryption
          when "lockbox"
            template "model_lockbox.rb", "app/models/ahoy/message.rb", lockbox_method: lockbox_method
          when "activerecord"
            template "model_activerecord.rb", "app/models/ahoy/message.rb"
          end
        end

        def migration_version
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end

        def to_column
          case encryption
          when "lockbox"
            "t.text :to_ciphertext\n      t.string :to_bidx, index: true"
          else
            if encryption == "activerecord" && mysql?
              "t.string :to, limit: 510, index: true"
            else
              "t.string :to, index: true"
            end
          end
        end

        # TODO remove default
        def encryption
          case options[:encryption]
          when "lockbox", "activerecord", "none"
            options[:encryption]
          when nil
            if options[:unencrypted]
              # TODO deprecation warning
              "none"
            else
              "lockbox"
            end
          else
            abort "Error: encryption must be lockbox, activerecord, or none"
          end
        end

        def lockbox_method
          if defined?(Lockbox::VERSION) && Lockbox::VERSION.to_i < 1
            "encrypts"
          else
            "has_encrypted"
          end
        end

        def mysql?
          adapter =~ /mysql|trilogy/i
        end

        def adapter
          ActiveRecord::Base.connection_db_config.adapter.to_s
        end
      end
    end
  end
end
