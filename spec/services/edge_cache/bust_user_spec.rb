require "rails_helper"

RSpec.describe EdgeCache::BustUser, type: :service do
  let(:user) { create(:user) }

  let(:paths) do
    username = user.username

    [
      "/#{username}",
      "/#{username}?i=i",
      "/#{username}/comments",
      "/#{username}/comments?i=i",
      "/#{username}/comments/?i=i",
      "/live/#{username}",
      "/live/#{username}?i=i",
      "/feed/#{username}",
    ]
  end

  before do
    paths.each do |path|
      allow(described_class).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(user)

    paths.each do |path|
      expect(described_class).to have_received(:bust).with(path).once
    end
  end
end
