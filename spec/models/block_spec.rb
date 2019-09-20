require "rails_helper"

RSpec.describe Block, type: :model do
  let(:user) { create(:user) }
  let(:block) { described_class.new(user: user, input_html: "hello") }

  it "creates processed_html after published!" do
    user.add_role(:super_admin)
    block.publish!
    expect(block.processed_html).to eq("hello")
  end

  it "is not valid without user" do
    block.user = nil
    expect(block).not_to be_valid
  end

  it "is not valid with non-admin user" do
    expect(block).not_to be_valid
  end
end
