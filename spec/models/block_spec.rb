require "rails_helper"

RSpec.describe Block, type: :model do

  it "creates processed_html after publishd!" do
    user = create(:user)
    user.add_role(:super_admin)
    block = Block.new
    block.input_html = "hello"
    block.user_id = user.id
    block.publish!
    expect(block.processed_html).to eq("hello")
  end

  it "is not valid without user" do
    block = Block.new
    block.input_html = "hello"
    expect(block).not_to be_valid
  end

  it "is not valid non-admin user" do
    user = create(:user)
    block = Block.new
    block.user_id = user.id
    block.input_html = "hello"
    expect(block).not_to be_valid
  end
end
