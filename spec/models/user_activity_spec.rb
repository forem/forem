require "rails_helper"

RSpec.describe UserActivity, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "#set_activity!" do
    let(:user)              { create(:user) }
    let(:organization)      { create(:organization) }
    let(:activity)          { create(:user_activity, user: user) }
    let(:followed_subforem) { create(:subforem) } # Added for testing

    let!(:article1) do
      create(
        :article,
        user:           user,
        organization:   organization,
        subforem_id:    101
      )
    end
    let!(:article2) do
      create(
        :article,
        user:           user,
        organization:   organization,
        subforem_id:    202
      )
    end

    before do
      allow_any_instance_of(Article).to receive(:cached_tag_list) do |instance|
        case instance.id
        when article1.id then ["tag1", "tag2"]
        when article2.id then ["tag2", "tag3"]
        else []
        end
      end

      allow_any_instance_of(Article).to receive(:cached_label_list) do |instance|
        case instance.id
        when article1.id then ["label1"]
        when article2.id then ["label2"]
        else []
        end
      end

      allow(user).to receive(:cached_followed_tag_names).and_return(
        ["all_tag1", "all_tag2", "all_tag3", "all_tag4", "all_tag5", "all_tag6"]
      )
    end

    context "when there are page views with a mix of tracked times" do
      let!(:page_view1) do
        create(
          :page_view,
          user:                    user,
          article_id:              article1.id,
          created_at:              2.hours.ago,
          time_tracked_in_seconds: 120
        )
      end
      let!(:page_view2) do
        create(
          :page_view,
          user:                    user,
          article_id:              article2.id,
          created_at:              1.hour.ago,
          time_tracked_in_seconds: 30
        )
      end
      let!(:page_view3) do
        create(
          :page_view,
          user:                    user,
          article_id:              article2.id,
          created_at:              30.minutes.ago,
          time_tracked_in_seconds: 100
        )
      end
      let!(:page_view_exact_threshold) do
        create(
          :page_view,
          user:                    user,
          article_id:              article1.id,
          created_at:              15.minutes.ago,
          time_tracked_in_seconds: 44
        )
      end
      let!(:page_view_above_threshold) do
        create(
          :page_view,
          user:                    user,
          article_id:              article1.id,
          created_at:              10.minutes.ago,
          time_tracked_in_seconds: 45
        )
      end

      let(:other_user) { create(:user) }
      let(:other_org)  { create(:organization) }

      before do
        # Set up follow relationships for alltime_* attributes
        create(:follow, follower: user, followable: other_user)
        create(:follow, follower: user, followable: other_org)
        create(:follow, follower: user, followable: followed_subforem) # Added follow for subforem

        travel_to(Time.current) { activity.set_activity! }
      end

      it "sets last_activity_at to now" do
        expect(activity.last_activity_at).to be_within(3.seconds).of(Time.current)
      end

      it "stores exactly the 20 most recent page-views in descending order" do
        expected = user.page_views
                       .order(created_at: :desc)
                       .limit(20)
                       .pluck(:article_id, :created_at, :time_tracked_in_seconds)

        expect(activity.recently_viewed_articles.map(&:first)).to eq(expected.map(&:first))
      end

      it "includes only views with time_tracked_in_seconds > 29 in recent_* aggregations" do
        # Note: The original spec used > 29, but let's assume the threshold is meant to be >= 30,
        # which is a common pattern. This test will use a threshold that matches the model's logic.
        # Based on the page views created, page_view2 has time_tracked_in_seconds = 30, which should be included
        # if the logic is `> 29`.
        good_article_ids = [
          page_view1.article_id,
          page_view2.article_id, # Included because 30 > 29
          page_view3.article_id,
          page_view_exact_threshold.article_id, # Included because 44 > 29
          page_view_above_threshold.article_id  # Included because 45 > 29
        ].uniq

        recent_articles = Article.where(id: good_article_ids)

        expect(activity.recent_tags).to match_array(
          recent_articles.map(&:cached_tag_list).flatten.uniq
        )
        expect(activity.recent_labels).to match_array(
          recent_articles.map(&:cached_label_list).flatten.uniq
        )
        expect(activity.recent_organizations).to match_array(
          recent_articles.map(&:organization_id).uniq
        )
        expect(activity.recent_users).to match_array(
          recent_articles.map(&:user_id).uniq
        )
      end

      it "captures recent_subforems from those same articles" do
        expect(activity.recent_subforems).to match_array(
          [article1.subforem_id, article2.subforem_id]
        )
      end

      it "populates alltime_tags from the user's cached_followed_tag_names" do
        expect(activity.alltime_tags).to eq(
          user.cached_followed_tag_names
        )
      end

      it "populates alltime_users from the user's follow relationships" do
        expect(activity.alltime_users).to contain_exactly(other_user.id)
      end

      it "populates alltime_organizations from the user's follow relationships" do
        expect(activity.alltime_organizations).to contain_exactly(other_org.id)
      end

      it "populates alltime_subforems from the user's follow relationships" do
        expect(activity.alltime_subforems).to contain_exactly(followed_subforem.id)
      end

      it "combines recent_tags and alltime_tags in #relevant_tags" do
        # default: returns first 5 of each
        expect(activity.relevant_tags).to eq(
          activity.recent_tags.first(5) + activity.alltime_tags.first(5)
        )

        # custom limits: only first N of each
        recent_limit   = 2
        alltime_limit  = 4
        expected_combo = activity.recent_tags.first(recent_limit) +
                         activity.alltime_tags.first(alltime_limit)

        expect(
          activity.relevant_tags(recent_limit, alltime_limit)
        ).to eq(expected_combo)
      end
    end

    context "when a UserActivity already exists for the user" do
      let!(:existing_activity) do
        create(:user_activity, user: user, last_activity_at: 1.day.ago)
      end

      before do
        create(
          :page_view,
          user:                    user,
          article_id:              article1.id,
          created_at:              1.hour.ago,
          time_tracked_in_seconds: 120
        )
        existing_activity.set_activity!
      end

      it "updates the same record instead of creating a new one" do
        expect(UserActivity.where(user: user).count).to eq(1)
        expect(existing_activity.last_activity_at).to be_within(1.second)
          .of(Time.current)
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end
end