FactoryBot.define do
  factory :podcast_episode_rss_item, class: "Podcasts::EpisodeRssItem" do
    title { Faker::Book.title }
    itunes_subtitle { Faker::Hipster.words(3) }
    itunes_summary { Faker::Hipster.words(3) }
    link { Faker::Internet.url }
    guid { "<guid isPermaLink=\"false\">#{Faker::Internet.url}/2.mp3}</guid>" }
    pubDate { Faker::Date.between(2.years.ago, Time.zone.today) }
    body { Faker::Hipster.paragraph(1) }
    enclosure_url { "#{Faker::Internet.url}/2.mp3" }

    initialize_with { new(attributes) }
  end
end
