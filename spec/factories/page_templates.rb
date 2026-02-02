FactoryBot.define do
  factory :page_template do
    sequence(:name) { |n| "Page Template #{n}" }
    description { "A template for creating pages" }
    body_markdown { "# {{title}}\n\n{{content}}" }
    template_type { "contained" }
    data_schema do
      {
        "fields" => [
          { "name" => "title", "type" => "text", "label" => "Title", "required" => true },
          { "name" => "content", "type" => "textarea", "label" => "Content", "required" => false },
        ]
      }
    end

    trait :with_html do
      body_markdown { nil }
      body_html { "<h1>{{title}}</h1><div>{{content}}</div>" }
    end

    trait :minimal do
      description { nil }
      body_markdown { "{{content}}" }
      data_schema { { "fields" => [{ "name" => "content", "type" => "textarea" }] } }
    end
  end
end

