module DeliveryMethods
  # ActionMailer delivery method that hands the message to a Customer.io
  # event-triggered campaign instead of sending it. Selected per message by the
  # Deliverable concern when the mailer declares a customerio_event_name, the
  # Track API credentials are configured, and the :customerio_email_delivery
  # flag passes for the recipient.
  #
  # Rails still owns who, what and when; Customer.io owns rendering, sending and
  # conversion goals. Keeping ActionMailer in the loop is what makes that
  # affordable: AhoyEmail::Observer#delivered_email writes the ahoy_messages row
  # after any delivery method returns, so send counts and the digest's own
  # suppression gate keep working, and mail.ahoy_data is already populated by the
  # time deliver! runs, so the links inside the payload can be signed.
  #
  # Unlike the transactional path this is fire-and-forget from Rails' side: the
  # Track API accepting the event is not the same as Customer.io sending the
  # mail, which the campaign can still suppress afterwards. That divergence is
  # the reason the campaign is expected to carry exactly one suppression rule.
  class CustomerIoEvent
    attr_accessor :settings

    def initialize(delivery_method_options = {})
      self.settings = delivery_method_options
    end

    def deliver!(mail)
      # The gem does not wrap POST /v2/entity, but /v2/batch takes the same
      # entity objects and Customerio::Client#batch verifies the response, so a
      # rejected event raises here rather than being silently dropped -- which
      # is what keeps Ahoy from recording a row for a send that never happened.
      CUSTOMERIO_TRACK_API.batch([entity(mail)])
    end

    private

    def entity(mail)
      {
        type: "person",
        action: "event",
        # Resolved by Deliverable#customerio_identifiers, same as the
        # transactional path: the MLH Core uid where the account is linked,
        # falling back to email.
        identifiers: settings[:identifiers],
        name: settings[:customerio_event_name],
        attributes: attributes(mail)
      }
    end

    # Defaults are a floor, not a ceiling: message_data may override either.
    # recipient is set explicitly because the Customer.io profile is keyed on the
    # MLH person, whose primary address is not necessarily the DEV one -- the
    # campaign addresses the mail to {{event.recipient}}.
    def attributes(mail)
      {
        "recipient" => mail.to&.first,
        "subject" => mail.subject
      }.merge(tracked_message_data(mail))
    end

    # Customer.io renders from the event payload, so Ahoy's link rewriting --
    # which operates on the ActionMailer body -- never reaches the recipient.
    # Re-apply it here for the same reason DeliveryMethods::CustomerIo does.
    def tracked_message_data(mail)
      return {} if settings[:message_data].blank?

      Emails::AhoyLinkDecorator.call(settings[:message_data], ahoy_data: mail.ahoy_data)
    end
  end
end
