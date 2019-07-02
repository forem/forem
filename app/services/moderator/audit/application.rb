module Moderator
  module Audit
    class Application
      extend Dry::Configurable

      ACTION_TYPES = %i[removal downvote vomit vote].freeze

      # Custom instrumentation name used by ActiveSupport::Notifications
      setting :instrumentation_name, "moderator.audit.log".freeze
      # Action type which describe the action made by the moderator
      setting :types, ACTION_TYPES
    end
  end
end
