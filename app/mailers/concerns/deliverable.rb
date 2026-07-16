module Deliverable
  extend ActiveSupport::Concern

  CUSTOMERIO_FLAG = :customerio_email_delivery

  included do
    before_action :set_perform_deliveries
    after_action  :set_delivery_options
  end

  # Mailer actions call this before mail() to attach the Customer.io
  # transactional template id and its Liquid payload, e.g.
  #   customerio_delivery_options(transactional_message_id: "dev_new_reply_email",
  #                               message_data: { "comment" => ... })
  # Ignored unless the message routes through Customer.io.
  def customerio_delivery_options(options)
    @customerio_delivery_options = (@customerio_delivery_options || {}).merge(options)
  end

  def set_perform_deliveries
    self.perform_deliveries = ForemInstance.smtp_enabled?
  end

  def set_delivery_options
    if deliver_via_customerio?
      # Deliverable on a Customer.io-only instance (no SMTP creds) must still
      # send, so the per-message flag overrides the SMTP-based default above.
      message.perform_deliveries = true
      message.delivery_method(
        DeliveryMethods::CustomerIo,
        # identifiers are always controller-resolved and intentionally override
        # anything passed via customerio_delivery_options.
        (@customerio_delivery_options || {}).merge(identifiers: customerio_identifiers),
      )
    else
      mail.delivery_method.settings.merge!(Settings::SMTP.settings)
    end
  end

  private

  def deliver_via_customerio?
    return false unless ForemInstance.customerio_enabled?
    return false if mail.to.blank?

    if customerio_recipient
      FeatureFlag.enabled_for_user?(CUSTOMERIO_FLAG, customerio_recipient)
    else
      FeatureFlag.enabled?(CUSTOMERIO_FLAG)
    end
  end

  # The flag check and Customer.io identifiers both key off mail.to.first:
  # all Forem mailers are single-recipient today.
  def customerio_recipient
    return @customerio_recipient if defined?(@customerio_recipient)

    @customerio_recipient = User.find_by(email: mail.to.first.to_s.downcase)
  end

  # People in Customer.io are keyed by MLH Core user id (DEV profiles were
  # stitched via the dev:<id> anonymous id); fall back to email for
  # recipients without a linked Core account.
  def customerio_identifiers
    mlh_uid = customerio_recipient&.identities&.where(provider: "mlh")&.pick(:uid)
    return { id: mlh_uid } if mlh_uid.present?

    { email: mail.to.first }
  end
end
