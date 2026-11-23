require "rails_helper"

RSpec.describe Notifications::SyncEventDebounceWorker, type: :worker do
  let(:recipient) { create(:user) }
  let(:article) { create(:article, user: recipient) }

  before do
    allow(Notifications::SyncEvents).to receive(:sent)
    allow(Notifications::SyncEvents).to receive(:removed)
  end

  include_examples "#enqueues_on_correct_queue", "low_priority"

  it "sends the row's current state when it still exists" do
    notification = create(:notification, user: recipient, organization: nil, notifiable: article, action: "Reaction")

    described_class.new.perform(recipient.id, "Article", article.id, "Reaction")

    expect(Notifications::SyncEvents).to have_received(:sent)
      .with(notification, recipients: { recipient.id => notification.id })
  end

  it "reports the row as removed when it is gone" do
    described_class.new.perform(recipient.id, "Article", article.id, "Reaction")

    expect(Notifications::SyncEvents).to have_received(:removed).with(
      notifiable_type: "Article", notifiable_ids: [article.id], action: "Reaction",
      recipients: { recipient.id => nil }, reason: "reaction_removed"
    )
  end

  it "finds a user's follow notification even after its notifiable moved to a newer follow" do
    newer_follow = recipient.follow(create(:user))
    notification = create(:notification, user: recipient, organization: nil, notifiable: newer_follow, action: "Follow")

    described_class.new.perform(recipient.id, "Follow", newer_follow.id - 1, "Follow")

    expect(Notifications::SyncEvents).to have_received(:sent)
      .with(notification, recipients: { recipient.id => notification.id })
  end

  it "debounces follows per recipient and everything else per row" do
    expect(described_class.lock_args([1, "Follow", 5, "Follow"])).to eq([1, "Follow"])
    expect(described_class.lock_args([1, "Article", 5, "Reaction"])).to eq([1, "Article", 5, "Reaction"])
  end

  it "replaces a still-scheduled job, so the debounce is trailing" do
    expect(described_class.get_sidekiq_options).to include("lock" => :until_executing, "on_conflict" => :replace,
                                                           "lock_args_method" => :lock_args)
  end
end
