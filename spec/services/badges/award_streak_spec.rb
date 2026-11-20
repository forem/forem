require "rails_helper"

RSpec.describe Badges::AwardStreak, type: :service do
  let(:user) { create(:user) }

  before do
    create(:badge, title: "4 Week Streak", slug: "4-week-streak")
    create(:article, :past, user: user, published: true, past_published_at: 26.days.ago)
    create(:article, :past, user: user, published: true, past_published_at: 19.days.ago)
    create(:article, :past, user: user, published: true, past_published_at: 5.days.ago)
  end

  it "awards badge to users with four straight weeks of articles" do
    create(:article, :past, user: user, published: true, past_published_at: 12.days.ago)
    expect do
      described_class.call(weeks: 4)
    end.to change { user.reload.badges.size }.by(1)
  end

  it "does not award the badge to not qualified users" do
    expect do
      described_class.call(weeks: 4)
    end.not_to change { user.reload.badges.size }
  end

  it "does not award when week 1 article score is at or below MINIMUM_QUALITY" do
    create(:article, :past, user: user, published: true, past_published_at: 12.days.ago)
    user.articles.where("published_at > ?", 1.week.ago).update_all(score: described_class::MINIMUM_QUALITY)

    expect do
      described_class.call(weeks: 4)
    end.not_to change(BadgeAchievement, :count)
  end

  it "skips users who already hold the badge without re-querying their weeks" do
    create(:article, :past, user: user, published: true, past_published_at: 12.days.ago)
    described_class.call(weeks: 4)
    expect(user.reload.badges.size).to eq(1)

    second_user = create(:user)
    [26, 19, 12, 5].each do |days|
      create(:article, :past, user: second_user, published: true, past_published_at: days.days.ago)
    end

    queries = []
    callback = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:cached] || payload[:name] == "SCHEMA"
      next unless payload[:sql].include?('FROM "articles"')

      binds = payload[:type_casted_binds]
      binds = binds.call if binds.respond_to?(:call)
      queries << { sql: payload[:sql], binds: Array(binds) }
    end

    expect do
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.call(weeks: 4)
      end
    end.to change(BadgeAchievement, :count).by(1)

    expect(second_user.reload.badges.size).to eq(1)
    # 1 candidate lookup (with recent-author subquery) + 1 grouped bucket query for un-awarded users only
    expect(queries.size).to eq(2)
    bucket_query = queries.last
    expect(bucket_query[:sql]).to include("GROUP BY")
    expect(bucket_query[:binds]).to include(second_user.id)
    expect(bucket_query[:binds]).not_to include(user.id)
  end
end
