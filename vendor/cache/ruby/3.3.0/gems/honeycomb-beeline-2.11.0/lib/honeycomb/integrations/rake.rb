# frozen_string_literal: true

require "rake"

Rake::TaskManager.record_task_metadata = true

module Honeycomb
  module Rake
    ##
    # Automatically capture rake tasks and create a trace
    #
    module Task
      def execute(args = nil)
        return super(args) if honeycomb_client.nil?

        honeycomb_client.start_span(name: "rake.#{name}") do |span|
          span.add_field("meta.package", "rake")
          span.add_field("meta.package_version", ::Rake::VERSION)
          full_comment && span.add_field("rake.description", full_comment)
          arg_description && span.add_field("rake.arguments", arg_description)
          super(args)
        end
      end

      attr_writer :honeycomb_client

      def honeycomb_client
        return @honeycomb_client if defined?(@honeycomb_client)

        application.honeycomb_client
      end
    end

    ##
    # Provide access to the honeycomb_client for the rake tasks, can be
    # provided or uses the default global honeycomb client
    #
    module Application
      attr_writer :honeycomb_client

      def honeycomb_client
        return @honeycomb_client if defined?(@honeycomb_client)

        Honeycomb.client
      end
    end
  end
end

Rake::Application.include(Honeycomb::Rake::Application)
Rake::Task.prepend(Honeycomb::Rake::Task)
