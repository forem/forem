FactoryBot.define do
  factory :profile do
    user { association(:user, _skip_creating_profile: true) }
  end

  trait :with_DEV_info do
    data do
      {
        education: "DEV University",
        employment_title: "Software Engineer",
        employer_name: "DEV",
        employer_url: "http://dev.to",
        currently_learning: "Preact",
        mostly_work_with: "Ruby",
        currently_hacking_on: "JSON-LD",
        mastodon_url: "https://mastodon.social/@test",
        facebook_url: "www.facebook.com/example",
        linkedin_url: "www.linkedin.com/company/example",
        youtube_url: "https://youtube.com/example",
        behance_url: "www.behance.net/#{user.username}",
        stackoverflow_url: "www.stackoverflow.com/example",
        dribbble_url: "www.dribbble.com/example",
        medium_url: "www.medium.com/example",
        gitlab_url: "www.gitlab.com/example",
        instagram_url: "www.instagram.com/example"
      }
    end
  end
end
