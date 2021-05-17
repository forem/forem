require "rails_helper"

RSpec.describe Users::SuggestForSidebar, type: :service do
  let(:user) { create(:user) }

  it "returns user suggestions" do
    tags = "html"
    article1 = create(:article, tags: tags)
    article2 = create(:article, tags: tags)
    expect(described_class.new(user, tags).suggest.to_a).to match_array([article1.user, article2.user])
  end

  it "returns no user if there's not enough sample" do
    create_list(:user, 3)
    tags = create_list(:tag, 3)
    expect(described_class.new(user, tags).suggest).to be_empty
  end
end
