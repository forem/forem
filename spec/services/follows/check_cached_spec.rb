require "rails_helper"

RSpec.describe Follows::CheckCached, type: :service do
  let(:user) { create(:user) }

  it "checks if following a thing and returns true if they are" do
    user2 = create(:user)
    user.follow(user2)
    expect(described_class.call(user, "User", user2.id)).to be(true)
  end

  it "checks if following a thing and returns false if they are not" do
    user2 = create(:user)
    expect(described_class.call(user, "User", user2.id)).to be(false)
  end

  it "checks tag follows" do
    tag = create(:tag)
    user.follow(tag)
    expect(described_class.call(user, "Tag", tag.id)).to be(true)
  end

  it "raises when the followable does not exist" do
    expect { described_class.call(user, "User", 0) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "loads only the followable's id" do
    user2 = create(:user)
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      described_class.call(user, "User", user2.id)
    end
    expect(queries).to include(a_string_including('SELECT "users"."id" FROM "users"'))
    expect(queries).not_to include(a_string_including('SELECT "users".* FROM "users"'))
  end
end
