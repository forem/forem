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
