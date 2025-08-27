FactoryBot.define do
  factory :context_note do
    article
    tag

    transient do
      content { "This is a context note." }
    end

    body_markdown { content }
    processed_html { content }

    after(:build) do |context_note, evaluator|
      context_note.processed_html = evaluator.content
    end
  end
end