# enable tracking for open, click and UTM params
AhoyEmail.api = false
AhoyEmail.default_options[:click] = Rails.env.production? ? ENV["AHOY_EMAIL_CLICK_ON"] == "YES" : true
AhoyEmail.default_options[:utm_params] = false
AhoyEmail.default_options[:message] = true

# Monkeypatch to make track_links work async instead of as a blocking route.
require "ahoy_email"

module AhoyEmail
  class Processor
    protected

    # rubocop:disable Metrics/CyclomaticComplexity
    def track_links
      return unless html_part?

      part = message.html_part || message

      doc = Nokogiri::HTML::Document.parse(part.body.raw_source)
      doc.css("a[href]").each do |link|
        uri = parse_uri(link["href"])
        next unless trackable?(uri)

        if options[:utm_params] && !skip_attribute?(link, "utm-params")
          existing_params = uri.query_values(Array) || []
          UTM_PARAMETERS.each do |key|
            next if existing_params.any? { |k, _v| k == key } || !options[key.to_sym]
            existing_params << [key, options[key.to_sym]]
          end
          uri.query_values = existing_params
        end

        if options[:click] && !skip_attribute?(link, "click")
          signature = Utils.signature(token: token, campaign: campaign, url: link["href"])
          tracking_params = {
            "ahoy_click" => true,
            "t" => token,
            "s" => signature,
            "u" => CGI.escape(link["href"]),
            "c" => campaign
          }.reject { |_k, v| v.nil? || v.to_s.empty? }

          # Merge the existing and new tracking params
          all_params = (uri.query_values(Array) || []) + tracking_params.to_a
          uri.query_values = all_params

          # Preserve the port if present, especially for localhost in development
          port_part = uri.port ? ":#{uri.port}" : ""
          link["href"] = "#{uri.scheme}://#{uri.host}#{port_part}#{uri.path}"
          link["href"] += "?#{uri.query}" unless uri.query.nil? || uri.query.empty?
        end
      end
      part.body = doc.to_s.gsub("&amp;", "&")
    end
  end
end
