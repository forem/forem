require "rails_helper"

RSpec.describe Suggester::Users::Sidebar, type: :service do
  let(:user) { create(:user) }

  xit "does not include calling user" do
    create_list(:user, 3)
    tags = []
    3.times { tags << create(:tag) }
    expect(described_class.new(user, tags).suggest).not_to include(user)
  end

  xit "returns the same number created" do
    create_list(:user, 3)
    tags = []
    3.times { tags << create(:tag) }
    expect(described_class.new(user, tags).suggest.size).to eq(0)
  end
end
