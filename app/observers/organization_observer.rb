class OrganizationObserver < ActiveRecord::Observer
  def after_create(organization)
    return if Rails.env.development?

    SlackBotPingWorker.perform_async(
      "New Org Created: #{organization.name}\nhttps://dev.to/#{organization.username}", # message
      "orgactivity", # channel
      "org_bot", # username
      ":office:", # icon_emoji
    )
  rescue StandardError => e
    Rails.logger.error(e)
  end
end
