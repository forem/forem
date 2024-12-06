# frozen_string_literal: true

require 'securerandom'

require_relative 'ext'
require_relative '../utils/forking'

module Datadog
  module Core
    module Environment
      # For runtime identity
      # @public_api
      module Identity
        extend Core::Utils::Forking

        module_function

        # Retrieves number of classes from runtime
        def id
          @id ||= ::SecureRandom.uuid.freeze

          # Check if runtime has changed, e.g. forked.
          after_fork! { @id = ::SecureRandom.uuid.freeze }

          @id
        end

        def pid
          ::Process.pid
        end

        def lang
          Core::Environment::Ext::LANG
        end

        def lang_engine
          Core::Environment::Ext::LANG_ENGINE
        end

        def lang_interpreter
          Core::Environment::Ext::LANG_INTERPRETER
        end

        def lang_platform
          Core::Environment::Ext::LANG_PLATFORM
        end

        def lang_version
          Core::Environment::Ext::LANG_VERSION
        end

        # Returns tracer version, rubygems-style
        def tracer_version
          Core::Environment::Ext::TRACER_VERSION
        end

        # Returns tracer version, comforming to https://semver.org/spec/v2.0.0.html
        def tracer_version_semver2
          # from ddtrace/version.rb, we have MAJOR.MINOR.PATCH plus optional .PRE and .BUILD
          # - transform .PRE to -PRE if present
          # - transform .BUILD to +BUILD if present
          # - keep triplet segments before that

          m = SEMVER2_RE.match(tracer_version)

          pre = "-#{m[:pre]}" if m[:pre]
          build = "+gha#{m[:gha_run_id]}.g#{m[:git_sha]}.#{m[:branch].tr('.', '-')}" if m[:build]

          "#{m[:major]}.#{m[:minor]}.#{m[:patch]}#{pre}#{build}"
        end

        SEMVER2_RE = /
          ^
          # mandatory segments
          (?<major>\d+)
          \.
          (?<minor>\d+)
          \.
          (?<patch>\d+)

          # pre segments start with a value
          # - containing at least one alpha
          # - that is not part of our build segments expected values
          # and stop with a value that is not part of our build segments expected values
          (?:
            \.
            (?<pre>
              (?!gha)
              [a-zA-Z0-9]*[a-zA-Z][a-zA-Z0-9]*
              (?:
                \.
                (?!gha)
                [a-zA-Z0-9]+
              )*
            )
          )?

          # build segments: ours include CI info (`gha`), then git (`g`), then branch name
          (?:
            \.
            (?<build>
              gha(?<gha_run_id>\d+)
              \.
              g(?<git_sha>[a-f0-9]+)
              \.
              (?<branch>(?:[a-zA-Z0-9.])+)
            )
          )?
          $
        /xm.freeze
      end
    end
  end
end
