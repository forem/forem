require "rails_helper"

# Each notification write path reports itself through Notifications::SyncEvents.
RSpec.describe Notifications::SyncEvents, type: :service do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:reader) { create(:user) }
  let(:other_reader) { create(:user) }

  let(:events) { [] }

  def sent_events
    events_named("notifications_sent")
  end

  def events_named(event_name)
    events.filter_map { |name, kwargs| kwargs if name == event_name }
  end

  def recipient_rows(event)
    event[:recipient_ids].zip(event[:recipient_properties]["notification_ids"])
  end

  before do
    allow(Trackable::BatchEvent).to receive(:enqueue) { |name, **kwargs| events << [name, kwargs] }
    allow(FeatureFlag).to receive(:enabled?).and_call_original
    allow(FeatureFlag).to receive(:enabled?).with(:notification_sync_events).and_return(true)
  end

  it "sends nothing while the flag is off" do
    allow(FeatureFlag).to receive(:enabled?).with(:notification_sync_events).and_return(false)
    reader.follow(author)

    Notifications::NotifiableAction::Send.call(article, "Published")

    expect(Trackable::BatchEvent).not_to have_received(:enqueue)
  end

  it "sends one event for a published post's whole follower fan-out" do
    reader.follow(author)
    other_reader.follow(author)

    Notifications::NotifiableAction::Send.call(article, "Published")

    expect(sent_events.size).to eq(1)
    expect(sent_events.first).to include(
      recipient_ids: contain_exactly(reader.id, other_reader.id),
      properties: hash_including("kind" => "new_post", "notifiable_id" => article.id, "action" => "Published"),
    )
    expect(recipient_rows(sent_events.first))
      .to match_array(Notification.where(notifiable: article, action: "Published").pluck(:user_id, :id))
  end

  it "sends the existing row's id when a fan-out re-notifies" do
    reader.follow(author)
    Notifications::NotifiableAction::Send.call(article, "Published")
    first_id = Notification.find_by(user: reader, notifiable: article).id

    Notifications::NotifiableAction::Send.call(article, "Published")

    expect(sent_events.map { |event| recipient_rows(event) }).to eq([[[reader.id, first_id]]] * 2)
  end

  it "sends one event for a comment's fan-out instead of one per row" do
    create(:notification_subscription, user: reader, notifiable: article, config: "all_comments")
    create(:notification_subscription, user: other_reader, notifiable: article, config: "all_comments")
    comment = create(:comment, commentable: article)

    Notifications::NewComment::Send.call(comment)

    expect(sent_events.size).to eq(1)
    expect(sent_events.first[:recipient_ids])
      .to match_array(Notification.where(notifiable: comment).where.not(user_id: nil).pluck(:user_id))
    expect(sent_events.first[:recipient_ids]).to include(reader.id, other_reader.id)
    expect(recipient_rows(sent_events.first))
      .to match_array(Notification.where(notifiable: comment).where.not(user_id: nil).pluck(:user_id, :id))
  end

  it "sends single-row creates from the commit callback, including community favorites" do
    Badges::AwardCommunityFavorite.call(favoritable: article, favoriter: reader)

    expect(sent_events.size).to eq(1)
    expect(sent_events.first).to include(
      recipient_ids: [author.id],
      recipient_properties: { "notification_ids" => [Notification.find_by(user: author, action: "Favorited").id] },
      properties: hash_including("kind" => "community_favorite", "action" => "Favorited"),
    )
  end

  it "never sends moderation notifications" do
    create(:notification, user: reader, organization: nil, notifiable: article, action: "Moderation")

    expect(sent_events).to be_empty
  end

  it "debounces reaction notifications instead of sending them inline" do
    reaction = create(:reaction, reactable: article, user: reader)
    Notifications::SyncEventDebounceWorker.clear

    Notifications::Reactions::Send.call(Notifications::Reactions::ReactionData.coerce(reaction).to_h, author)

    expect(sent_events).to be_empty
    expect(Notifications::SyncEventDebounceWorker.jobs.pluck("args"))
      .to eq([[author.id, "Article", article.id, "Reaction"]])
  end

  it "debounces the removal when a post's last reaction is undone" do
    reaction = create(:reaction, reactable: article, user: reader)
    data = Notifications::Reactions::ReactionData.coerce(reaction).to_h
    Notifications::Reactions::Send.call(data, author)
    reaction.destroy
    Notifications::SyncEventDebounceWorker.clear

    Notifications::Reactions::Send.call(data, author)

    expect(Notifications::SyncEventDebounceWorker.jobs.size).to eq(1)
  end

  it "debounces follow notifications" do
    follow = reader.follow(author)

    Notifications::NewFollower::Send.call(Notifications::NewFollower::FollowData.coerce(follow).to_h)

    expect(sent_events).to be_empty
    expect(Notifications::SyncEventDebounceWorker.jobs.last["args"]).to eq([author.id, "Follow", follow.id, "Follow"])
  end

  it "sends refreshed content after a post edit" do
    reader.follow(author)
    Notifications::NotifiableAction::Send.call(article, "Published")
    article.update_columns(title: "A new title")

    Notifications::Update.call(article.reload, "Published")

    expect(events_named("notifications_updated").first).to include(
      recipient_ids: nil,
      properties: hash_including("notifiable_id" => article.id, "action" => "Published",
                                 "text" => a_string_ending_with("A new title")),
    )
  end

  context "when rows are removed" do
    before do
      reader.follow(author)
      Notifications::NotifiableAction::Send.call(article, "Published")
    end

    it "reports RemoveAll for every action on the notifiables" do
      Notifications::RemoveAll.call([article.id], "Article")

      expect(events_named("notifications_removed").first[:properties])
        .to include("notifiable_ids" => [article.id], "all_actions" => true, "reason" => "content_removed")
    end

    it "reports an unpublish through RemoveAllByAction" do
      Notifications::RemoveAllByAction.call([article.id], "Article", "Published")

      expect(events_named("notifications_removed").first[:properties])
        .to include("action" => "Published", "all_actions" => false, "reason" => "unpublished")
    end

    it "reports a spammer's removed rows" do
      Notifications::RemoveBySpammer.call(author)

      expect(events_named("notifications_removed").first[:properties])
        .to include("notifiable_type" => "Article", "action" => "Published", "reason" => "spam")
    end

    it "sends nothing when no row was deleted" do
      Notifications::RemoveAll.call([article.id + 1000], "Article")

      expect(events_named("notifications_removed")).to be_empty
    end
  end

  it "reports a removed co-author to that person only" do
    article.update_columns(co_author_ids: [reader.id])
    Notifications::CoAuthor::Send.call(article.reload)
    notification_id = Notification.find_by(user: reader, action: "CoAuthor").id

    Notifications::CoAuthor::Remove.call(article.id, [reader.id, other_reader.id])

    expect(sent_events.first).to include(recipient_ids: [reader.id], properties: hash_including("kind" => "co_author"))
    expect(recipient_rows(sent_events.first)).to eq([[reader.id, notification_id]])
    expect(events_named("notifications_removed").first).to include(
      recipient_ids: [reader.id], properties: hash_including("action" => "CoAuthor", "reason" => "co_author_removed"),
    )
    expect(recipient_rows(events_named("notifications_removed").first)).to eq([[reader.id, notification_id]])
  end
end
