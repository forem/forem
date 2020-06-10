require "rails_helper"

RSpec.describe Suggester::Users::Sidebar, type: :service do
  let(:user) { create(:user) }

  it "returns user suggestions" do
    create_list(:user, 2)
    tags = "html"
    article1 = create(:article, tags: tags)
    article2 = create(:article, tags: tags)
    expect(described_class.new(user, tags).suggest).to eq([article1.user, article2.user])
  end

  it "returns the same number created" do
    create_list(:user, 3)
    tags = []
    3.times { tags << create(:tag) }
    expect(described_class.new(user, tags).suggest.size).to eq(0)
  end
end
