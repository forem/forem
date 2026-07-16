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

    # Header used to smuggle the Customer.io delivery id from this
    # delivery method's API response through to ahoy_email's post-delivery
    # save hook, which only ever sees the Mail::Message (not this return
    # value). See config/initializers/ahoy_email.rb, which reads this
    # header off the same mail object and strips it before persisting.
    DELIVERY_ID_HEADER = "X-CIO-Delivery-ID".freeze

    def initialize(delivery_method_options = {})
      self.settings = DEFAULTS.merge(delivery_method_options)
    end

    def deliver!(mail)
      request = Customerio::SendEmailRequest.new(build_message(mail))
      mail.attachments.each do |attachment|
        request.attach(attachment.filename, attachment.body.to_s)
      end

      response = CUSTOMERIO_API.send_email(request)
      stash_delivery_id(mail, response)
      response
    end

    private

    # Capturing the delivery id is purely for the click-backfill webhook;
    # a failure here must never take down the send itself.
    def stash_delivery_id(mail, response)
      delivery_id = response["delivery_id"] if response.is_a?(Hash)
      mail[DELIVERY_ID_HEADER] = delivery_id if delivery_id.present?
    rescue StandardError => e
      Honeybadger.notify(e, context: { source: "DeliveryMethods::CustomerIo#stash_delivery_id" })
    end

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

    # Customer.io's body field is HTML. Prefer the html_part (Mail searches
    # nested multipart structures recursively), falling back to the text part
    # or the raw body for single-part mail.
    def build_body(mail)
      part = mail.html_part || mail.text_part
      (part || mail).body.to_s
    end
  end
end
