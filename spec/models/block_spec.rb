require "rails_helper"

RSpec.describe Block, type: :model do

  it "creates processed_html after publishd!" do
    block = Block.new
    block.input_html = "hello"
    block.publish!
    expect(block.processed_html).to eq("hello")
  end

end