FactoryBot.define do
  factory :feedback_message do
    transient do
      reporter_id 1
    end

    after(:create) do |feedback_message, evaluator|
      feedback_message.update(reporter_id: evaluator.reporter_id)
    end
  end


  trait :abuse_report do
    feedback_type { "abuse-reports" }
    message       { "this is spam" }
    category      { "spam" }
    reported_url  { "https://dev.to" }
  end

  trait :bug_report do
    feedback_type { "bug-reports" }
    message       { "i clicked something and this happened" }
    category      { "bugs" }
  end
end
