module Articles
  class JsonCreator
    def self.organization(organization)
      {
        "@context": "http://schema.org",
        "@type": "Organization",
        "mainEntityOfPage": {
          "@type": "WebPage",
          "@id": URL.organization(organization)
        },
        "url": URL.organization(organization),
        "image": Images::Profile.call(organization.profile_image_url, length: 320),
        "name": organization.name,
        "description": organization.summary.presence || "404 bio not found"
      }
    end

    def user(user)
      {
        "@context": "http://schema.org",
        "@type": "Person",
        "mainEntityOfPage": {
          "@type": "WebPage",
          "@id": URL.user(user)
        },
        "url": URL.user(user),
        "sameAs": user_same_as(user),
        "image": Images::Profile.call(user.profile_image_url, length: 320),
        "name": user.name,
        "email": user.email_public ? user.email : nil,
        "jobTitle": user.employment_title.presence,
        "description": user.summary.presence || "404 bio not found",
        "disambiguatingDescription": user_disambiguating_description(user),
        "worksFor": [user_works_for(user)].compact,
        "alumniOf": user.education.presence
      }.reject { |_, v| v.blank? }
    end

    def article(article, user)
      {
        "@context": "http://schema.org",
        "@type": "Article",
        "mainEntityOfPage": {
          "@type": "WebPage",
          "@id": URL.article(article)
        },
        "url": URL.article(article),
        "image": seo_optimized_images(article),
        "publisher": {
          "@context": "http://schema.org",
          "@type": "Organization",
          "name": "#{SiteConfig.community_name} Community",
          "logo": {
            "@context": "http://schema.org",
            "@type": "ImageObject",
            "url": ApplicationController.helpers.optimized_image_url(SiteConfig.logo_png, width: 192,
                                                                                          fetch_format: "png"),
            "width": "192",
            "height": "192"
          }
        },
        "headline": article.title,
        "author": {
          "@context": "http://schema.org",
          "@type": "Person",
          "url": URL.user(user),
          "name": user.name
        },
        "datePublished": article.published_timestamp,
        "dateModified": article.edited_at&.iso8601 || article.published_timestamp
      }
    end

    private

    def seo_optimized_images(article)
      # This array of images exists for SEO optimization purposes.
      # For more info on this structure, please refer to this documentation:
      # https://developers.google.com/search/docs/data-types/article
      [
        ApplicationController.helpers.article_social_image_url(article, width: 1080, height: 1080),
        ApplicationController.helpers.article_social_image_url(article, width: 1280, height: 720),
        ApplicationController.helpers.article_social_image_url(article, width: 1600, height: 900),
      ]
    end

    def user_disambiguating_description(user)
      [user.mostly_work_with, user.currently_hacking_on, user.currently_learning].compact
    end

    def user_same_as(user)
      # For further information on the sameAs property, please refer to this link:
      # https://schema.org/sameAs
      [
        user.twitter_username.presence ? "https://twitter.com/#{user.twitter_username}" : nil,
        user.github_username.presence ? "https://github.com/#{user.github_username}" : nil,
        user.mastodon_url,
        user.facebook_url,
        user.youtube_url,
        user.linkedin_url,
        user.behance_url,
        user.stackoverflow_url,
        user.dribbble_url,
        user.medium_url,
        user.gitlab_url,
        user.instagram_url,
        user.twitch_username,
        user.website_url,
      ].reject(&:blank?)
    end

    def user_works_for(user)
      # For further examples of the worksFor and disambiguatingDescription properties,
      # please refer to this link: https://jsonld.com/person/
      return unless user.employer_name.presence || user.employer_url.presence

      {
        "@type": "Organization",
        "name": user.employer_name,
        "url": user.employer_url
      }.reject { |_, v| v.blank? }
    end
  end
end
