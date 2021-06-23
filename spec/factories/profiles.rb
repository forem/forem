FactoryBot.define do
  factory :profile do
    user { association(:user, _skip_creating_profile: true) }
  end

  trait :with_DEV_info do
    data do
      {
        currently_hacking_on: "JSON-LD",
        currently_learning: "Preact",
        education: "DEV University",
        employer_name: "DEV",
        employer_url: "http://dev.to",
        employment_title: "Software Engineer",
        skills_languages: "Ruby",
        summary: "I do things with computers",
        website_url: "http://example.com"
      }
    end
  end
end
