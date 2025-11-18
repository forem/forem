FactoryBot.define do
  factory :trend do
    subforem
    short_title { "AI Trends" }
    public_description { "This is a public description of the trend." }
    full_content_description { "This is the full content description that the system uses to understand and match articles to this trend." }
    expiry_date { 1.month.from_now }
  end
end

