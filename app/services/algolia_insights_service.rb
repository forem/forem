class AlgoliaInsightsService
  include HTTParty
  base_uri "https://insights.algolia.io/1"

  def initialize(application_id = nil, api_key = nil)
    @application_id = application_id || Settings::General.algolia_application_id
    @api_key = api_key || Settings::General.algolia_api_key
  end

  def track_event(event_type, event_name, user_id, object_id, index_name, timestamp = nil)
    headers = {
      "X-Algolia-Application-Id" => @application_id,
      "X-Algolia-API-Key" => @api_key,
      "Content-Type" => "application/json"
    }
    payload = {
      events: [
        {
          eventType: event_type,
          eventName: event_name,
          index: index_name,
          userToken: user_id.to_s,
          objectIDs: [object_id.to_s],
          timestamp: timestamp || (Time.now.to_i * 1000)
        },
      ]
    }

    response = self.class.post("/events", headers: headers, body: payload.to_json)
    if response.success?
      Rails.logger.debug { "Event tracked: #{response.body}" }
    else
      Rails.logger.debug { "Failed to track event: #{response.body}" }
    end
  end

  # WIP, this is for backfilling data, but not something we are doing now due to potential de-dupe problems.
  def track_insights_for_article(article)
    article.page_views.where.not(user_id: nil).find_each do |page_view|
      track_event(
        "view",
        "Article Viewed",
        page_view.user_id,
        page_view.article_id,
        "Article_#{Rails.env}",
        page_view.created_at.to_i * 1000, # Adding timestamp from the page view
      )
    end
    article.reactions.public_category.each do |reaction|
      track_event(
        "conversion",
        "Reaction Created",
        reaction.user_id,
        article.id,
        "Article_#{Rails.env}",
        reaction.created_at.to_i * 1000, # Adding timestamp from the reaction
      )
    end
  end
end
