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
      options = @customerio_delivery_options || {}
      message.delivery_method(
        DeliveryMethods::CustomerIo,
        options.merge(
          # identifiers are always controller-resolved and intentionally override
          # anything passed via customerio_delivery_options.
          identifiers: customerio_identifiers,
          # layout data is a floor, not a ceiling: a mailer may override any of
          # it by passing the same key through customerio_delivery_options.
          message_data: layout_message_data.merge(options[:message_data] || {}),
        ),
      )
    else
      mail.delivery_method.settings.merge!(Settings::SMTP.settings)
    end
  end

  private

  # Data the Customer.io layout needs on every message, mirroring the block
  # layouts/mailer.html.erb renders at the bottom of each email. Resolved
  # through view_context so signed_up_with/app_url pick up the same helpers
  # and subforem-aware host the ERB layout uses.
  #
  # Emitted only where that block renders today, which takes all three guards
  # below: a recipient in @user, an action the ERB layout does not exclude,
  # and a view context that actually has AuthenticationHelper.
  def layout_message_data
    user = instance_variable_get(:@user)
    return {} if user.blank? || action_name == "magic_link"

    # DeviseMailer inherits from Devise::Mailer rather than ApplicationMailer,
    # so it renders without layouts/mailer.html.erb and without
    # AuthenticationHelper. Its security emails have never carried this footer
    # (note Devise's initialize_from_record still sets @user, so the ivar alone
    # is not a reliable signal) -- keep them as they are.
    context = view_context
    return {} unless context.respond_to?(:signed_up_with)

    {
      # "name" is here rather than in each mailer because seven templates greet
      # the recipient without otherwise needing a payload of their own.
      "name" => user.name,
      "signed_up_with_html" => context.signed_up_with(user),
      "notification_settings_url" => context.app_url(context.user_settings_path(:notifications))
    }
  end

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
