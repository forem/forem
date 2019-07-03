require "rails_helper"

RSpec.describe Poll, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:poll) { create(:poll, article_id: article.id) }

  it "limits length of prompt" do
    long_string = "0" * 200
    poll.prompt_markdown = long_string
    expect(poll).not_to be_valid
  end

  it "creates options from input" do
    poll = create(:poll, article_id: article.id, poll_options_input_array: %w[hello goodbye heyheyhey])
    expect(poll.poll_options.size).to eq(3)
  end
end
