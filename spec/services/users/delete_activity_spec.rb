require "rails_helper"

RSpec.describe Users::DeleteActivity, type: :service do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:article) { create(:article, user: other_user) }

  # Forces several batches with a handful of records
  before { stub_const("#{described_class}::BATCH_SIZE", 2) }

  it "deletes the user's notifications across batches" do
    create_list(:notification, 3, user: user)
    kept = create(:notification, user: other_user)

    described_class.call(user)

    expect(Notification.ids).to eq([kept.id])
  end

  it "deletes the user's reactions across batches" do
    create_list(:article, 3).each { |a| create(:reaction, user: user, reactable: a, category: "like") }
    kept = create(:reaction, user: other_user, reactable: article, category: "like")

    described_class.call(user)

    expect(Reaction.ids).to eq([kept.id])
  end

  it "deletes reactions to the user across batches" do
    create_list(:user, 3, :trusted).each { |reactor| create(:vomit_reaction, user: reactor, reactable: user) }
    kept = create(:vomit_reaction, reactable: other_user)

    described_class.call(user)

    expect(Reaction.ids).to eq([kept.id])
  end

  it "deletes who the user follows and their followers across batches", :aggregate_failures do
    create_list(:user, 3).each do |followed|
      user.follow(followed)
      followed.follow(user)
    end
    kept = other_user.follow(create(:user))

    described_class.call(user)

    expect(Follow.where(follower: user)).to be_empty
    expect(Follow.followable_user(user.id)).to be_empty
    expect(Follow.ids).to eq([kept.id])
  end

  it "deletes the user's email messages across batches" do
    create_list(:ahoy_message, 3, user: user)
    kept = create(:ahoy_message, user: other_user)

    described_class.call(user)

    expect(Ahoy::Message.ids).to eq([kept.id])
  end

  it "keeps the user's billboard events but detaches them from the user" do
    billboard_event = create(:billboard_event, user: user)

    described_class.call(user)

    expect(billboard_event.reload.user_id).to be_nil
  end

  it "resets already loaded associations it deleted in batches" do
    create(:notification, user: user)
    user.notifications.load

    described_class.call(user)

    expect(user.notifications).to be_empty
  end
end
