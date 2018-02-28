require 'rails_helper'

RSpec.describe Follow, type: :model do
  after { StreamRails.enabled = false }

  let(:user) { create(:user) }
  let(:user_2) { create(:user) }

  before do
    StreamRails.enabled = true #Test with StreamRails
    allow(StreamNotifier).to receive(:new).and_call_original
  end
  it "follows user" do
    user.follow(user_2)
    expect(user.following?(user_2)).to eq(true)
  end
end
