FactoryBot.define do
  factory :search_keyword do
    keyword               { Faker::Book.title }
    google_result_path    { "/username_#{rand(10000)}/slug_#{rand(100000)}" }
    google_position       { rand(200) }
    google_volume          { rand(100000) }
    google_difficulty      { rand(100) }
    google_checked_at      { 3.weeks.ago }
  end
end
