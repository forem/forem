class OrganizationObserver < ActiveRecord::Observer
  def after_create(organization)
    return if Rails.env.development?

    SlackBotPingJob.perform_later(
      message: "New Org Created: #{organization.name}\nhttps://dev.to/#{organization.username}",
      channel: "orgactivity",
      username: "org_bot",
      icon_emoji: ":office:",
    )
  rescue StandardError => e
    Rails.logger.error(e)
  end
end
