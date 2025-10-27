FactoryBot.define do
  factory :poll do
    article
    prompt_markdown { Faker::Hipster.words(number: 5) }
    poll_options_input_array { [rand(5).to_s, rand(5).to_s, rand(5).to_s, rand(5).to_s] }
    poll_options_supplementary_text_array { nil }
    type_of { :single_choice }
    position { 0 }

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

    trait :with_supplementary_text do
      poll_options_supplementary_text_array { ["Desc 1", "Desc 2", "Desc 3", "Desc 4"] }
    end

    trait :scale_with_supplementary_text do
      type_of { :scale }
      poll_options_input_array { %w[1 2 3 4 5] }
      poll_options_supplementary_text_array { ["Very dissatisfied", nil, nil, nil, "Very satisfied"] }
    end
  end
end
