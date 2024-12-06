# frozen_string_literal: true

module Pundit
  module Matchers
    module Utils
      # Collects all details about given policy class.
      class PolicyInfo
        attr_reader :policy

        def initialize(policy)
          @policy = policy
        end

        def actions
          @actions ||= begin
            policy_methods = @policy.public_methods - Object.instance_methods
            policy_methods.grep(/\?$/).map { |policy_method| policy_method.to_s.sub(/\?$/, '').to_sym }
          end
        end

        def permitted_actions
          @permitted_actions ||= actions.select { |action| policy.public_send("#{action}?") }
        end

        def forbidden_actions
          actions - permitted_actions
        end
      end
    end
  end
end
