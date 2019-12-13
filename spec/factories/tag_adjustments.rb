FactoryBot.define do
  factory :tag_adjustment do
    user_id               { 1 }
    article_id            { 1 }
    tag_id                { 1 }
    tag_name              { "NOTHING" }
    adjustment_type       { "addition" }
    reason_for_adjustment { "reason #{rand(10_000)}" }
    status                { "committed" }
  end
end
# t.integer   :user_id
# t.integer   :article_id
# t.integer   :tag_id
# t.string    :tag_name
# t.string    :adjustment_type
# t.string    :status
# t.string    :reason_for_adjustment
