require 'honeybadger/util/sql'

module Honeybadger
  module Breadcrumbs
    class ActiveSupport
      def self.default_notifications
        {
          # ActiveRecord Actions
          #
          "sql.active_record" => {
            message: lambda do |data|
              # Disregard empty string names
              name = data[:name] if data[:name] && !data[:name].strip.empty?

              ["Active Record", name].compact.join(" - ")
            end,
            category: "query",
            select_keys: [:sql, :name, :connection, :connection_id, :cached],
            transform: lambda do |data|
              if data[:sql]
                connection = data.delete(:connection)
                adapter = (connection && connection.adapter_name.downcase) || active_record_connection_db_config[:adapter]
                data[:sql] = Util::SQL.obfuscate(data[:sql], adapter)
              end
              data
            end,
            exclude_when: lambda do |data|
              # Ignore schema, begin, and commit transaction queries
              data[:name] == "SCHEMA" ||
                (data[:sql] && (Util::SQL.force_utf_8(data[:sql].dup) =~ /^(begin|commit)( transaction)?$/i))
            end
          },

          # ActionCable Actions
          #
          "perform_action.action_cable" => {
            message: "Action Cable Perform Action",
            select_keys: [:channel_class, :action],
            category: "render"
          },

          # ActiveJob Actions
          #
          "enqueue.active_job" => {
            message: "Active Job Enqueue",
            select_keys: [],
            category: "job"
          },
          "perform_start.active_job" => {
            message: "Active Job Perform Start",
            select_keys: [],
            category: "job",
          },

          # ActiveSupport Actions
          #
          "cache_read.active_support" => {
            message: "Active Support Cache Read",
            category: "query"
          },
          "cache_fetch_hit.active_support" => {
            message: "Active Support Cache Fetch Hit",
            category: "query"
          },

          # Controller Actions
          #
          "halted_callback.action_controller" => {
            message: "Action Controller Callback Halted",
            category: "request",
          },
          "process_action.action_controller" => {
            message: "Action Controller Action Process",
            select_keys: [:controller, :action, :format, :method, :path, :status, :view_runtime, :db_runtime],
            category: "request",
          },
          "start_processing.action_controller" => {
            message: "Action Controller Start Process",
            select_keys: [:controller, :action, :format, :method, :path],
            category: "request",
          },
          "redirect_to.action_controller" => {
            message: "Action Controller Redirect",
            category: "request",
          },

          # View Actions
          #
          "render_template.action_view" => {
            message: "Action View Template Render",
            category: "render",
          },
          "render_partial.action_view" => {
            message: "Action View Partial Render",
            category: "render",
          },

          # Mailer actions
          #
          "deliver.action_mailer" => {
            message: "Action Mailer Deliver",
            select_keys: [:mailer, :message_id, :from, :date],
            category: "render"
          }
        }
      end

      private_class_method def self.active_record_connection_db_config
        if ::ActiveRecord::Base.respond_to?(:connection_db_config)
          # >= Rails 6.1
          ::ActiveRecord::Base.connection_db_config.configuration_hash
        else
          # < Rails 6.1
          ::ActiveRecord::Base.connection_config
        end
      end
    end
  end
end
