require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20201030134117_reindex_users_for_username_search.rb")

describe DataUpdateScripts::ReindexUsersForUsernameSearch do
  let(:user) { create :user }

  it "reindexes users" do
    sidekiq_assert_enqueued_with(job: Search::BulkIndexWorker, args: ["User", [user.id]], queue: "default") do
      described_class.new.run
    end
  end
end
