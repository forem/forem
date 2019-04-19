require 'rails_helper'

RSpec.describe ClassifiedListing, type: :model do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body_markdown) }

  let(:user) { create(:user)}
  let(:classified_listing) { create(:classified_listing, user_id: user.id)}

  describe "body html" do
    it "converts markdown to html" do
      expect(classified_listing.processed_html).to include("<p>")
    end
  end
end
