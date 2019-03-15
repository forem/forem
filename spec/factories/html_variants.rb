FactoryBot.define do
  factory :html_variant do
    user
    name          { Faker::Hipster.paragraph(1) }
    html          { "<div>#{rand(10_000_000_000)}</div><h1>HEllo</h1>" }
    success_rate  { 0.3 }
    group         { "article_show_sidebar_cta" }
  end
end
