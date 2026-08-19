module DeliveryMethods
  # ActionMailer delivery method that sends through the Customer.io App API
  # (transactional messages) instead of SMTP. Selected per message by the
  # Deliverable concern when CUSTOMERIO_APP_KEY is configured and the
  # :customerio_email_delivery flag passes for the recipient.
  class CustomerIo
    attr_accessor :settings

    DEFAULTS = {
      tracked: true
    }.freeze

    # Customer.io renders the message itself, so headers set on the Mail object
    # are not carried over unless we forward them explicitly. RFC 8058
    # one-click unsubscribe only works if these reach the recipient.
    FORWARDED_HEADERS = %w[List-Unsubscribe List-Unsubscribe-Post].freeze

    def initialize(delivery_method_options = {})
      self.settings = DEFAULTS.merge(delivery_method_options)
    end

    def deliver!(mail)
      request = Customerio::SendEmailRequest.new(build_message(mail))
      mail.attachments.each do |attachment|
        request.attach(attachment.filename, attachment.body.to_s)
      end

      CUSTOMERIO_API.send_email(request)
    end

    private

    def build_message(mail)
      {}.tap do |message|
        # With a transactional_message_id the Customer.io template renders the
        # content; without one this is a body passthrough send.
        message[:body] = build_body(mail) unless settings[:transactional_message_id]
        message[:from] = mail.from.first if mail.from
        message[:subject] = mail.subject if mail.subject
        message[:identifiers] = { email: mail.to.first } if mail.to
        message[:reply_to] = mail.reply_to.first if mail.reply_to
        message[:to] = mail.to.join(",") if mail.to
        forwarded = forwarded_headers(mail)
        message[:headers] = forwarded if forwarded.any?
      end.merge(settings).merge(tracked_message_data(mail))
    end

    # Customer.io renders from message_data, so Ahoy's link rewriting -- which
    # operates on the ActionMailer body -- never reaches the recipient. Re-apply
    # it to the payload so clicks still reach Ahoy::EmailClicksController.
    #
    # mail.ahoy_data is set by AhoyEmail::Processor in an after_action. Rails
    # runs after_actions in reverse registration order, so it lands *after*
    # Deliverable#set_delivery_options picks this delivery method -- which is
    # why the token is read here at delivery time rather than captured into
    # settings when the delivery method was chosen.
    def tracked_message_data(mail)
      return {} if settings[:message_data].blank?

      { message_data: Emails::AhoyLinkDecorator.call(settings[:message_data], ahoy_data: mail.ahoy_data) }
    end

    def forwarded_headers(mail)
      FORWARDED_HEADERS.each_with_object({}) do |name, headers|
        value = mail[name]&.value
        headers[name] = value if value.present?
      end
    end

    # Customer.io's body field is HTML. Prefer the html_part (Mail searches
    # nested multipart structures recursively), falling back to the text part
    # or the raw body for single-part mail.
    def build_body(mail)
      part = mail.html_part || mail.text_part
      (part || mail).body.to_s
    end
  end
end
