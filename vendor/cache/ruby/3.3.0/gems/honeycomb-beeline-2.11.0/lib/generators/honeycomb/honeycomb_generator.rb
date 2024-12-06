# frozen_string_literal: true

require "rails/generators"
require "active_support/core_ext/string/strip"

##
# Generates an intializer for configuring the Honeycomb beeline
#
class HoneycombGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  argument :write_key, required: true, desc: "required"

  class_option :service_name, type: :string, default: "rails"

  gem "honeycomb-beeline"

  desc "Configures honeycomb with your write key"

  def create_initializer_file
    initializer "honeycomb.rb" do
      <<-RUBY.strip_heredoc
        Honeycomb.configure do |config|
          config.write_key = #{write_key.inspect}
          config.service_name = #{options['service_name'].inspect}
          config.presend_hook do |fields|
            if fields["name"] == "redis" && fields.has_key?("redis.command")
              # remove potential PII from the redis command
              if fields["redis.command"].respond_to? :split
                fields["redis.command"] = fields["redis.command"].split.first
              end
            end
            if fields["name"] == "sql.active_record"
              # remove potential PII from the active record events
              fields.delete("sql.active_record.binds")
              fields.delete("sql.active_record.type_casted_binds")
            end
          end
          config.notification_events = %w[
            sql.active_record
            render_template.action_view
            render_partial.action_view
            render_collection.action_view
            process_action.action_controller
            send_file.action_controller
            send_data.action_controller
            deliver.action_mailer
          ].freeze
        end
      RUBY
    end
  end
end
