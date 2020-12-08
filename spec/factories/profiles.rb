FactoryBot.define do
  factory :profile do
    user { association(:user, _skip_creating_profile: true) }
  end

  trait :with_DEV_info do
    data do
      {
        behance_url: "www.behance.net/#{user.username}",
        currently_hacking_on: "JSON-LD",
        currently_learning: "Preact",
        dribbble_url: "www.dribbble.com/example",
        education: "DEV University",
        employer_name: "DEV",
        employer_url: "http://dev.to",
        employment_title: "Software Engineer",
        facebook_url: "www.facebook.com/example",
        gitlab_url: "www.gitlab.com/example",
        instagram_url: "www.instagram.com/example",
        linkedin_url: "www.linkedin.com/company/example",
        mastodon_url: "https://mastodon.social/@test",
        medium_url: "www.medium.com/example",
        skills_languages: "Ruby",
        stackoverflow_url: "www.stackoverflow.com/example",
        youtube_url: "https://youtube.com/example",
        summary: "I do things with computers",
        website_url: "http://example.com"
      }
    end
  end
end
