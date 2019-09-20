require "rails_helper"

RSpec.describe PollOption, type: :model do
  let(:article) { create(:article, featured: true) }
  let(:poll) { create(:poll, article_id: article.id) }

  it "allows up to 128 markdown characters" do
    poll_option = described_class.create(markdown: "0" * 30, poll_id: poll.id)
    expect(poll_option).to be_valid
  end
  it "disallows over 128 markdown characters" do
    poll_option = described_class.create(markdown: "0" * 200, poll_id: poll.id)
    expect(poll_option).not_to be_valid
  end
end
