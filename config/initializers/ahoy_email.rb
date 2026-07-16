click_tracking_enabled = Rails.env.production? ? ENV["AHOY_EMAIL_CLICK_ON"] == "YES" : true
AhoyEmail.api = false
AhoyEmail.save_token = click_tracking_enabled
AhoyEmail.subscribers << AhoyEmail::MessageSubscriber if click_tracking_enabled
AhoyEmail.default_options[:click] = click_tracking_enabled
AhoyEmail.default_options[:utm_params] = false
AhoyEmail.default_options[:message] = true

# Monkeypatch to make track_links work async instead of as a blocking route.
require "ahoy_email"

module AhoyEmail
  class Processor
    protected

    def track_links
      return unless html_part?

      part = message.html_part || message

      doc = Nokogiri::HTML::Document.parse(part.body.raw_source)
      doc.css("a[href]").each do |link|
        process_link(link)
      end

      part.body = doc.to_s.gsub("&amp;", "&")
    end

    private

    def process_link(link)
      uri = parse_uri(link["href"])
      return unless trackable?(uri)

      add_utm_params(uri, link) if options[:utm_params] && !skip_attribute?(link, "utm-params")

      return unless options[:click] && !skip_attribute?(link, "click")

      signature = Utils.signature(token: token, campaign: campaign, url: link["href"])

      if internal_link?(uri)
        handle_internal_link(uri, link, signature)
      else
        handle_external_link(uri, link, signature)
      end
    end

    def add_utm_params(uri, link)
      existing_params = uri.query_values(Array) || []
      UTM_PARAMETERS.each do |key|
        next if existing_params.any? { |k, _v| k == key } || !options[key.to_sym]

        existing_params << [key, options[key.to_sym]]
      end
      uri.query_values = existing_params

      # Update the href for external links after adding UTM parameters
      link["href"] = uri.to_s unless internal_link?(uri)
    end

    def internal_link?(uri)
      uri.host == Settings::General.app_domain
    end

    def handle_internal_link(uri, link, signature)
      tracking_params = {
        "ahoy_click" => true,
        "t" => token,
        "s" => signature,
        "u" => CGI.escape(link["href"]),
        "c" => campaign
      }.reject { |_k, v| v.nil? || v.to_s.empty? }

      # Merge existing and tracking params
      all_params = (uri.query_values(Array) || []) + tracking_params.to_a
      uri.query_values = all_params

      # Reconstruct the href with updated parameters
      port_part = uri.port ? ":#{uri.port}" : ""
      link["href"] = "#{uri.scheme}://#{uri.host}#{port_part}#{uri.path}"
      link["href"] += "?#{uri.query}" unless uri.query.nil? || uri.query.empty?
    end

    def handle_external_link(uri, link, signature)
      link["href"] = url_for(
        controller: "ahoy/messages",
        action: "click",
        t: token,
        c: campaign,
        u: link["href"],
        s: signature,
      )
    end
  end
end

# Capture Customer.io's delivery id onto the EmailMessage (Ahoy::Message)
# row so clicks reported by CIO's webhook can be backfilled onto
# clicked_at (see IncomingWebhooks::CustomerioEventsController).
#
# Investigated first: the EmailMessage row is created by
# AhoyEmail.track_method, invoked from AhoyEmail::Tracker#perform, which
# only runs *after* delivery -- as a Mail delivery observer
# (AhoyEmail::Observer.delivered_email, registered via
# ActionMailer's register_observer, itself calling Mail.register_observer).
# Mail::Message#deliver! calls delivery_method.deliver!(self) and then
# informs observers with that same `self` (see mail gem's message.rb and
# mail.rb#inform_observers) -- so a header written onto the mail object by
# DeliveryMethods::CustomerIo#deliver! (after the CIO API call, once the
# delivery_id is known) is still present on that identical object when
# track_method builds the Ahoy row from it. That is the only point in the
# pipeline where the delivery_id (known only post-API-call) and the
# to-be-persisted row (known only post-delivery) coexist, so wrapping
# track_method is the correct hook -- there's no earlier, cleaner
# extension point: Processor#track_message (which seeds ahoy_data) runs
# pre-delivery, before the CIO response exists.
#
# We wrap rather than replace track_method so upstream ahoy_email content
# handling (message.encoded, click token, utm params, etc.) keeps working
# unmodified across gem upgrades. The header is stripped before the
# original method runs so it never leaks into the stored `content` column
# (content is message.encoded -- the raw, header-included source).
original_ahoy_track_method = AhoyEmail.track_method

AhoyEmail.track_method = lambda do |data|
  mail_message = data[:message]
  delivery_id = nil

  begin
    header = mail_message[DeliveryMethods::CustomerIo::DELIVERY_ID_HEADER]
    delivery_id = header&.value
    mail_message[DeliveryMethods::CustomerIo::DELIVERY_ID_HEADER] = nil if delivery_id
  rescue StandardError => e
    Honeybadger.notify(e, context: { source: "ahoy_email delivery id capture" })
  end

  ahoy_message = original_ahoy_track_method.call(data)

  if delivery_id.present? && ahoy_message.respond_to?(:cio_delivery_id=)
    begin
      ahoy_message.update_column(:cio_delivery_id, delivery_id)
    rescue StandardError => e
      Honeybadger.notify(e, context: { source: "ahoy_email delivery id capture", ahoy_message_id: ahoy_message.id })
    end
  end

  ahoy_message
end
