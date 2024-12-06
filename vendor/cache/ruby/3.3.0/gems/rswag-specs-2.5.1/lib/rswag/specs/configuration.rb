# frozen_string_literal: true

module Rswag
  module Specs
    class Configuration
      def initialize(rspec_config)
        @rspec_config = rspec_config
      end

      def swagger_root
        @swagger_root ||= begin
          if @rspec_config.swagger_root.nil?
            raise ConfigurationError, 'No swagger_root provided. See swagger_helper.rb'
          end

          @rspec_config.swagger_root
        end
      end

      def swagger_docs
        @swagger_docs ||= begin
          if @rspec_config.swagger_docs.nil? || @rspec_config.swagger_docs.empty?
            raise ConfigurationError, 'No swagger_docs defined. See swagger_helper.rb'
          end

          @rspec_config.swagger_docs
        end
      end

      def swagger_dry_run
        return @swagger_dry_run if defined? @swagger_dry_run
        if ENV.key?('SWAGGER_DRY_RUN')
          @rspec_config.swagger_dry_run = ENV['SWAGGER_DRY_RUN'] == '1'
        end
        @swagger_dry_run = @rspec_config.swagger_dry_run.nil? || @rspec_config.swagger_dry_run
      end

      def swagger_format
        @swagger_format ||= begin
          @rspec_config.swagger_format = :json if @rspec_config.swagger_format.nil? || @rspec_config.swagger_format.empty?
          raise ConfigurationError, "Unknown swagger_format '#{@rspec_config.swagger_format}'" unless [:json, :yaml].include?(@rspec_config.swagger_format)

          @rspec_config.swagger_format
        end
      end

      def get_swagger_doc(name)
        return swagger_docs.values.first if name.nil?
        raise ConfigurationError, "Unknown swagger_doc '#{name}'" unless swagger_docs[name]

        swagger_docs[name]
      end

      def get_swagger_doc_version(name)
        doc = get_swagger_doc(name)
        doc[:openapi] || doc[:swagger]
      end
    end

    class ConfigurationError < StandardError; end
  end
end
