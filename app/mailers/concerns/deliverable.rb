module Deliverable
  extend ActiveSupport::Concern

  included do
    before_action :set_perform_deliveries
    after_action  :set_delivery_options
  end

  def set_perform_deliveries
    self.perform_deliveries = ForemInstance.smtp_enabled?
  end

  def set_delivery_options
    mail.delivery_method.settings.merge!(Settings::SMTP.settings)
  end
end
