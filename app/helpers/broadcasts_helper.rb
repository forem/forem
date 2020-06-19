module BroadcastsHelper
  def banner_class(broadcast)
    return if broadcast.banner_style.blank?

    if broadcast.banner_style == "default"
      "crayons-banner"
    else
      "crayons-banner crayons-banner--#{broadcast.banner_style}"
    end
  end

  def sanitized_broadcast_id(broadcast_title)
    broadcast_title.downcase.delete(":").tr(" ", "_")
  end
end
