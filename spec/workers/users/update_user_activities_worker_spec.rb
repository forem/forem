require "rails_helper"

RSpec.describe Users::UpdateUserActivitiesWorker, type: :worker do
  let(:user) { create(:user) }

  [false, true].each do |existing_activity|
    context "with #{existing_activity ? 'an existing' : 'a new'} activity" do
      before do
        create(:user_activity, user: user) if existing_activity
        user
      end

      it "updates activity while loading the user only once" do
        user_queries = []
        callback = lambda do |*, payload|
          user_queries << payload[:sql] if payload[:sql].include?('FROM "users"')
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          described_class.new.perform(user.id)
        end

        activity = UserActivity.find_by!(user_id: user.id)
        expect(activity.last_activity_at).to be_within(5.seconds).of(Time.current)
        expect(activity.recently_viewed_articles).to eq([])
        expect(activity.alltime_tags).to eq(user.cached_followed_tag_names)
        expect(user_queries.size).to eq(1)
      end
    end
  end

  it "does not create activity for a missing or nil user" do
    expect do
      described_class.new.perform(0)
      described_class.new.perform(nil)
    end.not_to change(UserActivity, :count)
  end
end
