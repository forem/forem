require "rails_helper"

RSpec.describe Moderators::BustCacheJob, type: :job do
  include_examples "#enqueues_job", "moderators_bust_cache", [1]

  describe "#perform_now" do
    # build then save to skip validations
    # an after_validate callback changes the old_username
    let(:user) { FactoryBot.build(:user, old_username: Faker::Name.name) }

    it "busts users old username" do
      user.save(validate: false)
      cache_buster = double
      allow(cache_buster).to receive(:bust)

      described_class.perform_now(user.id, cache_buster)
      expect(cache_buster).to have_received(:bust).with("/#{user.old_username}")
    end
  end
end
