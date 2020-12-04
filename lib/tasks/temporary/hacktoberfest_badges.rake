# TODO: Will be removed my @mstruve once badges are rewarded for 2020
# rubocop:disable  Metrics/BlockLength
task award_hacktoberfest_badges: :environment do
  badge_id = Badge.find_by(slug: "hacktoberfest-2020")&.id
  user_ids = UserSubscription.where(
    user_subscription_sourceable_id: 529_344,
    created_at: 2.hours.ago..Time.current,
  ).pluck(:subscriber_id)

  User.where(id: user_ids).includes(:identities).find_each do |user|
    next if user.badges.exists?(id: badge_id)

    identity = user.identities.github.first
    next unless identity

    github_user_id = identity.uid
    response = HTTParty.get(
      "https://hacktoberfest.digitalocean.com/api/state/#{github_user_id}",
      headers: { "Authorization" => ENV["HACKTOBERFEST_AUTH_KEY"] },
    )
    if response.parsed_response == "completed"
      BadgeAchievement.create(
        user_id: user.id,
        badge_id: badge_id,
        rewarding_context_message_markdown: "Congrats!",
      )
      user.save
    end
  rescue StandardError => e
    Honeybadger.context(user_id: user.id)
    Honeybadger.notify(e)
  end
end
# rubocop:enable  Metrics/BlockLength
