require "rails_helper"

RSpec.describe "Follows #show" do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }
  let(:organization) { create(:organization) }
  let(:podcast) { create(:podcast) }

  before { sign_in current_user }

  def get_following_status
    %w[User Organization Tag Podcast].map do |type|
      get "/follows/#{__send__(type.downcase).id}", params: { followable_type: type }
      response.body
    end
  end

  it "rejects unless logged-in" do
    sign_out(user)
    get "/follows/#{user.id}"
    expect(response.body).to eq("not-logged-in")
  end

  it "returns false when not following" do
    expect(get_following_status.uniq[0]).to eq("false")
  end

  it "returns true when is following" do
    %w[user organization tag].each { |followable| current_user.follow(__send__(followable)) }
    expect(get_following_status.uniq[0]).to eq("true")
  end

  it "return self if current_user try to follow themself" do
    get "/follows/#{current_user.id}", params: { followable_type: "User" }
    expect(response.body).to eq("self")
  end

  it "returns follow-back when current_user is followed by them" do
    user.follow(current_user)
    get "/follows/#{user.id}", params: { followable_type: "User" }
    expect(response.body).to eq("follow-back")
  end

  it "returns mutual when current_user is following them and they are following current_user" do
    current_user.follow(user)
    user.follow(current_user)
    get "/follows/#{user.id}", params: { followable_type: "User" }
    expect(response.body).to eq("mutual")
  end

  it "raises RecordNotFound for a user id that does not exist (unchanged)" do
    missing_id = User.maximum(:id).to_i + 1

    expect do
      get "/follows/#{missing_id}", params: { followable_type: "User" }
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "loads the followed-back candidate once with only cache-key columns and batches follows misses" do
    user_queries = []
    follow_queries = []
    callback = lambda do |*, payload|
      sql = payload[:sql]
      user_queries << sql if sql.match?(/FROM "users" WHERE "users"."id" = /)
      follow_queries << sql if sql.include?('FROM "follows"')
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get "/follows/#{user.id}", params: { followable_type: "User" }
    end

    expect(user_queries).to include(a_string_starting_with('SELECT "users"."id", "users"."updated_at" FROM "users"'))
    expect(user_queries).not_to include(a_string_starting_with('SELECT "users".* FROM "users"'))
    expect(user_queries).not_to include(a_string_starting_with('SELECT "users"."id" FROM "users"'))
    expect(follow_queries.size).to eq(1)
  end

  it "rejects a retained session after the user's password changes" do
    get "/follows/#{user.id}", params: { followable_type: "User" }
    expect(response.body).to eq("false")

    User.where(id: current_user.id).update_all(
      encrypted_password: "$2a$10$newpasswordsaltandhashvalue1234567890123456789012",
    )

    get "/follows/#{user.id}", params: { followable_type: "User" }
    expect(response.body).to eq("not-logged-in")
  end
end
