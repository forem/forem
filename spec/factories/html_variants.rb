FactoryBot.define do
  factory :html_variant do
    user
    name          { Faker::Hipster.paragraph(sentence_count: 1) }
    html          { "<div>#{rand(10_000_000_000)}</div><h1>HEllo</h1>" }
    group         { "article_show_below_article_cta" }
  end
end
