require "rails_helper"

RSpec.describe EdgeCache::BustUser, type: :service do
  let(:cache_bust) { instance_double(EdgeCache::Bust) }
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
      "/api/users/#{user.id}",
    ]
  end

  before do
    allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)

    paths.each do |path|
      allow(cache_bust).to receive(:call).with(path).once
    end
  end

  it "busts the cache" do
    described_class.call(user)

    paths.each do |path|
      expect(cache_bust).to have_received(:call).with(path).once
    end
  end
end
