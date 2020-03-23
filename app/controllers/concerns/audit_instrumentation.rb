module AuditInstrumentation
  extend ActiveSupport::Concern

  REDACTED_KEYS = %w[authenticity_token utf8 commit].freeze

  included do
    def notify(listener, user, slug)
      Audit::Notification.notify(listener) do |payload|
        payload.user_id = user.id
        payload.roles = user.roles.pluck(:name)
        payload.slug = slug
        if block_given?
          payload.data = yield
        end
      end
    end

    def cleanse_for_audit(data)
      data.reject { |key, _v| REDACTED_KEYS.include? key }
    end
  end
end
