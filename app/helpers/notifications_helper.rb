module NotificationsHelper
  REACTION_IMAGES = {
    "like" => "heart-filled.svg",
    "unicorn" => "unicorn-filled.svg",
    "hands" => "twemoji/hands.svg",
    "thinking" => "twemoji/thinking.svg",
    "readinglist" => "save-filled.svg",
    "thumbsdown" => "twemoji/thumb-down.svg",
    "vomit" => "twemoji/suspicious.svg"
  }.freeze

  def reaction_image(slug)
    if FeatureFlag.enabled?(:multiple_reactions)
      if (category = ReactionCategory[slug] || ReactionCategory["like"])
        "#{category.icon}.svg"
      end
    else
      # This is mostly original behavior, pre-multiple_reactions, modified to return
      # a "like" image if the actual reaction is one of the new ones
      REACTION_IMAGES[slug] || REACTION_IMAGES["like"]
    end
  end

  def reaction_category_name(slug)
    ReactionCategory[slug]&.name.presence || "unknown"
  end

  def render_each_notification_or_error(notifications, error:, &block)
    notifications.each do |notification|
      concat render_notification_or_error(notification, error: error, &block)
    end
  end

  def render_notification_or_error(notification, error:)
    capture { yield(notification) }
  rescue StandardError => e
    raise if Rails.env.development?

    Honeybadger.notify(e, context: { notification_id: notification.id })
    capture { render error }
  end

  def message_user_acted_maybe_org(data, action, if_org: "")
    key_to_link = ->(key) { link_to(data[key]["name"], data[key]["path"], class: "crayons-link fw-bold") }
    if if_org.present?
      I18n.t(
        action,
        user: key_to_link.call("user"),
        if_org: data["organization"] ? I18n.t(if_org, org: key_to_link.call("organization")) : "",
      )
    else
      I18n.t(action, user: key_to_link.call("user"))
    end.html_safe # rubocop:disable Rails/OutputSafety
  end
end
