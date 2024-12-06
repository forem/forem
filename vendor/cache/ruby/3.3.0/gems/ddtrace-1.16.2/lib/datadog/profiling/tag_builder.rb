# frozen_string_literal: true

require_relative '../core/utils'

module Datadog
  module Profiling
    # Builds a hash of default plus user tags to be included in a profile
    module TagBuilder
      include Datadog::Profiling::Ext::Transport::HTTP # Tag name constants

      def self.call(
        settings:,
        # Unified service tagging
        env: settings.env,
        service: settings.service,
        version: settings.version,
        # Other metadata
        host: Core::Environment::Socket.hostname,
        language: Core::Environment::Identity.lang,
        pid: Process.pid.to_s,
        profiler_version: Core::Environment::Identity.tracer_version,
        runtime_engine: Core::Environment::Identity.lang_engine,
        runtime_id: Core::Environment::Identity.id,
        runtime_platform: Core::Environment::Identity.lang_platform,
        runtime_version: Core::Environment::Identity.lang_version,
        # User-provided tags
        user_tags: settings.tags
      )
        tags = {
          # When changing or adding these, make sure they are kept in sync with
          # https://docs.google.com/spreadsheets/d/1LOGMf4c4Avbtn36uZ2SWvhIGKRPLM1BoWkUP4JYj7hA/ (Datadog internal link)
          FORM_FIELD_TAG_HOST => host,
          FORM_FIELD_TAG_LANGUAGE => language,
          FORM_FIELD_TAG_PID => pid,
          FORM_FIELD_TAG_PROFILER_VERSION => profiler_version,
          FORM_FIELD_TAG_RUNTIME => language, # This is known to be repeated from language, above
          FORM_FIELD_TAG_RUNTIME_ENGINE => runtime_engine,
          FORM_FIELD_TAG_RUNTIME_ID => runtime_id,
          FORM_FIELD_TAG_RUNTIME_PLATFORM => runtime_platform,
          FORM_FIELD_TAG_RUNTIME_VERSION => runtime_version,
        }
        tags[FORM_FIELD_TAG_ENV] = env if env
        tags[FORM_FIELD_TAG_SERVICE] = service if service
        tags[FORM_FIELD_TAG_VERSION] = version if version

        # Make sure everything is an utf-8 string, to avoid encoding issues in native code/libddprof/further downstream
        user_tags.merge(tags).map do |key, value|
          [Datadog::Core::Utils.utf8_encode(key), Datadog::Core::Utils.utf8_encode(value)]
        end.to_h
      end
    end
  end
end
