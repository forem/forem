FactoryBot.define do
  factory :podcast_episode_appearance do
    user factory: :user
    podcast_episode
  end
end
