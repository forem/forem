module Audit
  class Logger
    REDACTED_KEYS = %w[authenticity_token utf8 commit].freeze

    def self.log(listener, user, data = nil)
      Audit::Notification.notify(listener) do |payload|
        payload.user_id = user.id
        payload.roles = user.roles.pluck(:name)
        payload.slug = caller_locations(1, 1)[0].label # Get the method from the request
        payload.data = if block_given?
                         yield
                       else
                         filter_redacted_keys(data)
                       end
      end
    end

    def self.filter_redacted_keys(data)
      data.except(*REDACTED_KEYS)
    end
  end
end
