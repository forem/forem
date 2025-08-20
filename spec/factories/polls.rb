FactoryBot.define do
  factory :poll do
    article
    prompt_markdown { Faker::Hipster.words(number: 5) }
    poll_options_input_array { [rand(5).to_s, rand(5).to_s, rand(5).to_s, rand(5).to_s] }
    type_of { :single_choice }

    trait :multiple_choice do
      type_of { :multiple_choice }
    end

    trait :scale do
      type_of { :scale }
      poll_options_input_array { %w[1 2 3 4 5] } # Default options for scale
    end

    trait :text_input do
      type_of { :text_input }
      poll_options_input_array { [] } # Text input polls don't need options
    end
  end
end
