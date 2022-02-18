module DataUpdateScripts
  class AddAwardBadges
    def run
      Badges::AwardContributorFromGithub::BADGE_SLUGS.each do |badge_slug, badge_commits|
        next if Badge.id_for_slug(badge_slug).present?

        Badge.create!(
          slug: badge_slug,
          title: badge_slug.to_s.underscore.titleize,
          description: "Awarded for #{badge_commits} commits to the repository",
          badge_image: "#{badge_slug}.png",
        )
      end
    end
  end
end
