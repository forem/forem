FactoryBot.define do
  factory :poll do
    prompt_markdown { Faker::Hipster.words(5) }
    poll_options_input_array { [rand(5).to_s, rand(5).to_s, rand(5).to_s, rand(5).to_s] }
  end
end
