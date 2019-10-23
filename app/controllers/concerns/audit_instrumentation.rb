module AuditInstrumentation
  extend ActiveSupport::Concern

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
  end
end
