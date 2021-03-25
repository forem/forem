FactoryBot.define do
  factory :navigation_link do
    name { "#{Faker::Book.title} #{rand(1000)}" }
    url  { "#{Faker::Internet.url}/#{rand(1000)}" }
    icon { "<svg xmlns='http://www.w3.org/2000/svg'/></svg>" }

    trait :without_url_normalization do
      after(:build) do |navigation_link|
        navigation_link.class.skip_callback :save, :before, :strip_local_hostname
      end

      after(:create) do |navigation_link|
        navigation_link.class.set_callback :save, :before, :strip_local_hostname
      end
    end
  end
end
