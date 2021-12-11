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

  def reaction_image(category)
    REACTION_IMAGES[category]
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
