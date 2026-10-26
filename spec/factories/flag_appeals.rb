FactoryBot.define do
  factory :flag_appeal do
    association :user
    association :appealable, factory: :user
    reason { "My post/account was flagged by mistake." }
    status { :open }
    ai_recommendation { :human_review }
    ai_summary { "Pending AI assessment." }
    ai_confidence_score { 0.5 }
  end
end
