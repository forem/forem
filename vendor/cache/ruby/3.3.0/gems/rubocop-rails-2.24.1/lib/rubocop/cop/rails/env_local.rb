# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for usage of `Rails.env.development? || Rails.env.test?` which
      # can be replaced with `Rails.env.local?`, introduced in Rails 7.1.
      #
      # @example
      #
      #   # bad
      #   Rails.env.development? || Rails.env.test?
      #
      #   # good
      #   Rails.env.local?
      #
      class EnvLocal < Base
        extend AutoCorrector
        extend TargetRailsVersion

        MSG = 'Use `Rails.env.local?` instead.'
        LOCAL_ENVIRONMENTS = %i[development? test?].to_set.freeze

        minimum_target_rails_version 7.1

        # @!method rails_env_local_candidate?(node)
        def_node_matcher :rails_env_local_candidate?, <<~PATTERN
          (or
            (send (send (const {cbase nil? } :Rails) :env) $%LOCAL_ENVIRONMENTS)
            (send (send (const {cbase nil? } :Rails) :env) $%LOCAL_ENVIRONMENTS)
          )
        PATTERN

        def on_or(node)
          rails_env_local_candidate?(node) do |*environments|
            next unless environments.to_set == LOCAL_ENVIRONMENTS

            add_offense(node) do |corrector|
              corrector.replace(node, 'Rails.env.local?')
            end
          end
        end
      end
    end
  end
end
