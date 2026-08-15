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

    # The internal-link rules live in Emails::AhoyLinkTracking so that this
    # (which rewrites the rendered body, for SMTP) and
    # Emails::AhoyLinkDecorator (which rewrites the Customer.io message_data
    # payload) cannot drift apart. Both have to produce URLs that
    # Ahoy::EmailClicksController will verify.
    def process_link(link)
      uri = parse_uri(link["href"])
      return unless trackable?(uri)

      add_utm_params(uri, link) if options[:utm_params] && !skip_attribute?(link, "utm-params")

      return unless options[:click] && !skip_attribute?(link, "click")

      if Emails::AhoyLinkTracking.internal?(uri)
        link["href"] = Emails::AhoyLinkTracking.internal_url(
          uri, link["href"], token: token, campaign: campaign
        )
      else
        signature = Utils.signature(token: token, campaign: campaign, url: link["href"])
        handle_external_link(link, signature)
      end
    end

    def add_utm_params(uri, link)
      existing_params = uri.query_values(Array) || []
      UTM_PARAMETERS.each do |key|
        next if existing_params.any? { |k, _v| k == key } || !options[key.to_sym]

        existing_params << [key, options[key.to_sym]]
      end
      uri.query_values = existing_params

      # Written back for every link, not just external ones, so that
      # process_link can re-read the href without losing the UTM params it just
      # added. Internal links have their href rebuilt from the same uri
      # immediately afterwards, so this is a no-op for them.
      link["href"] = uri.to_s
    end

    def handle_external_link(link, signature)
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
