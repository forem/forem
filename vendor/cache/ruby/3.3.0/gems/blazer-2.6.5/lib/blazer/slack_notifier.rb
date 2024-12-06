require "net/http"

module Blazer
  class SlackNotifier
    def self.state_change(check, state, state_was, rows_count, error, check_type)
      check.split_slack_channels.each do |channel|
        text =
          if error
            error
          elsif rows_count > 0 && check_type == "bad_data"
            pluralize(rows_count, "row")
          end

        payload = {
          channel: channel,
          attachments: [
            {
              title: escape("Check #{state.titleize}: #{check.query.name}"),
              title_link: query_url(check.query_id),
              text: escape(text),
              color: state == "passing" ? "good" : "danger"
            }
          ]
        }

        post(payload)
      end
    end

    def self.failing_checks(channel, checks)
      text =
        checks.map do |check|
          "<#{query_url(check.query_id)}|#{escape(check.query.name)}> #{escape(check.state)}"
        end

      payload = {
        channel: channel,
        attachments: [
          {
            title: escape("#{pluralize(checks.size, "Check")} Failing"),
            text: text.join("\n"),
            color: "warning"
          }
        ]
      }

      post(payload)
    end

    # https://api.slack.com/docs/message-formatting#how_to_escape_characters
    # - Replace the ampersand, &, with &amp;
    # - Replace the less-than sign, < with &lt;
    # - Replace the greater-than sign, > with &gt;
    # That's it. Don't HTML entity-encode the entire message.
    def self.escape(str)
      str.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") if str
    end

    def self.pluralize(*args)
      ActionController::Base.helpers.pluralize(*args)
    end

    # checks shouldn't have variables, but in any case,
    # avoid passing variable params to url helpers
    # (known unsafe parameters are removed, but still not ideal)
    def self.query_url(id)
      Blazer::Engine.routes.url_helpers.query_url(id, ActionMailer::Base.default_url_options)
    end

    # TODO use return value
    def self.post(payload)
      if Blazer.slack_webhook_url.present?
        response = post_api(Blazer.slack_webhook_url, payload, {})
        response.is_a?(Net::HTTPSuccess) && response.body == "ok"
      else
        headers = {
          "Authorization" => "Bearer #{Blazer.slack_oauth_token}",
          "Content-type" => "application/json"
        }
        response = post_api("https://slack.com/api/chat.postMessage", payload, headers)
        response.is_a?(Net::HTTPSuccess) && (JSON.parse(response.body)["ok"] rescue false)
      end
    end

    def self.post_api(url, payload, headers)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 3
      http.read_timeout = 5
      http.post(uri.request_uri, payload.to_json, headers)
    end
  end
end
