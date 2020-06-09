module BroadcastsHelper
  def banner_class(broadcast)
    return if broadcast.banner_style.blank?

    if broadcast.banner_style == "default"
      "crayons-banner"
    else
      "crayons-banner crayons-banner--#{broadcast.banner_style}"
    end
  end
end
