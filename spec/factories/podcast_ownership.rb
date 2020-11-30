FactoryBot.define do
  factory :podcast_ownership do
    owner factory: :user
    podcast
  end
end
