FactoryBot.define do
  factory :podcast_episode_rss_item, class: "Podcasts::EpisodeRssItem" do
    title { Faker::Book.title }
    itunes_subtitle { Faker::Hipster.words(number: 3) }
    itunes_summary { Faker::Hipster.words(number: 3) }
    link { Faker::Internet.url }
    guid { "<guid isPermaLink=\"false\">#{Faker::Internet.url}/2.mp3}</guid>" }
    pubDate { Faker::Date.between(from: 2.years.ago, to: Time.zone.today) }
    body { Faker::Hipster.paragraph(sentence_count: 1) }
    enclosure_url { "#{Faker::Internet.url}/2.mp3" }

    initialize_with { new(attributes) }
  end
end
