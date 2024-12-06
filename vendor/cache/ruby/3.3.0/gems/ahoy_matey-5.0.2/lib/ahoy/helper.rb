module Ahoy
  module Helper
    def amp_event(name, properties = {})
      url = Ahoy::Engine.routes.url_helpers.events_url(
        url_options.slice(:host, :port, :protocol).merge(
          name: name,
          properties: properties,
          screen_width: "SCREEN_WIDTH",
          screen_height: "SCREEN_HEIGHT",
          platform: "Web",
          landing_page: "AMPDOC_URL",
          referrer: "DOCUMENT_REFERRER",
          random: "RANDOM"
        )
      )
      url = "#{url}&visit_token=${clientId(ahoy_visit)}&visitor_token=${clientId(ahoy_visitor)}"

      content_tag "amp-analytics" do
        content_tag "script", type: "application/json" do
          json_escape({
            requests: {
              pageview: url
            },
            triggers: {
              trackPageview: {
                on: "visible",
                request: "pageview"
              }
            },
            transport: {
              beacon: true,
              xhrpost: true,
              image: false
            }
          }.to_json).html_safe
        end
      end
    end
  end
end
