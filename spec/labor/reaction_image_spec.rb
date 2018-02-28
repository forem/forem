require 'rails_helper'

RSpec.describe ReactionImage do

  it "returns a category image" do
    expect(ReactionImage.new("unicorn").path).to eq("emoji/emoji-one-unicorn.png")
  end  

end