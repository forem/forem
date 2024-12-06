# frozen_string_literal: true

require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Qless
        module Configuration
          # Custom settings for the Qless integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            option :analytics_enabled do |o|
              o.type :bool
              o.env Ext::ENV_ANALYTICS_ENABLED
              o.default false
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            option :tag_job_data do |o|
              o.type :bool
              o.env Ext::ENV_TAG_JOB_DATA
              o.default false
            end

            option :tag_job_tags do |o|
              o.type :bool
              o.env Ext::ENV_TAG_JOB_TAGS
              o.default false
            end

            option :service_name
          end
        end
      end
    end
  end
end
