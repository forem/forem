require "rails_helper"

RSpec.describe EdgeCache::BustUser, type: :service do
  let(:buster) { instance_double(EdgeCache::Buster) }
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
    allow(EdgeCache::Buster).to receive(:new).and_return(buster)

    paths.each do |path|
      allow(buster).to receive(:bust).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(user)

    paths.each do |path|
      expect(buster).to have_received(:bust).with(path).once
    end
  end
end
