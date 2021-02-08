FactoryBot.define do
  factory :podcast_episode_appearance do
    user
    podcast_episode
    role { "guest" }
  end
end
