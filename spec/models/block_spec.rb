require "rails_helper"

RSpec.describe Block, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:block) { described_class.new(user: user, input_html: "hello") }

  it "creates processed_html after published!" do
    user.add_role(:super_admin)
    block.publish!
    expect(block.processed_html).to eq("hello")
  end

  it "is not valid without user" do
    expect(described_class.new(user: nil)).not_to be_valid
  end

  it "is not valid with non-admin user" do
    expect(block).not_to be_valid
  end
end
