module NotificationsHelper
  def reaction_image(slug)
    return unless (category = ReactionCategory[slug] || ReactionCategory["like"])

    "#{category.icon}.svg"
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
    end.html_safe
  end

  def mod_comment_user(data)
    return data["comment_user"] if data["comment_user"].present?

    comment_username = data["comment"]["path"].split("/")[1]
    { "name" => comment_username, "path" => "/#{comment_username}" }
  end

  def mod_article_user(data)
    return data["article_user"] if data["article_user"].present?

    article_username = data["article"]["path"].split("/")[1]
    { "name" => article_username, "path" => "/#{article_username}" }
  end

  # This is used in the notification view's cache key, so that cached
  # notification fragments can quickly be burst whenever a user
  # adjusts their subscriptions to comment notifications
  def subscription_status_indicator
    @subscription_status_indicator ||= current_user.notification_subscriptions.sum(:id)
  end
end
