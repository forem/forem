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
      end.merge(settings)
    end

    def build_body(mail)
      if mail.body.parts.length > 1
        mail.body.parts.first.body.to_s
      else
        mail.body.to_s
      end
    end
  end
end
