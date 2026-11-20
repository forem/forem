require "rails_helper"

RSpec.describe Users::BustProfileImageCacheWorker, type: :worker do
  let(:user) { create(:user) }

  before do
    allow(EdgeCache::PurgeByKey).to receive(:call)
  end

  it "busts the profile image cache key without hydrating the full user row" do
    user
    full_user_queries = []
    callback = lambda do |*, payload|
      full_user_queries << payload[:sql] if payload[:sql].include?('SELECT "users".*')
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      described_class.new.perform(user.id)
    end

    expect(EdgeCache::PurgeByKey).to have_received(:call).with(
      user.profile_image_record_key,
      fallback_paths: user.profile_cache_bust_paths,
    )
    expect(full_user_queries).to be_empty
  end

  it "does not fail when user is missing" do
    expect do
      described_class.new.perform(User.maximum(:id).to_i + 1)
    end.not_to raise_error
  end
end
