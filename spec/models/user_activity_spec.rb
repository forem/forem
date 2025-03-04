require "rails_helper"

RSpec.describe UserActivity, type: :model do
  describe "#set_activity" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }
    let(:activity) { create(:user_activity, user: user) }

    let!(:article1) { create(:article, user: user, organization: organization) }
    let!(:article2) { create(:article, user: user, organization: organization) }

    before do
      # Stub tag/label lists for any instance of Article.
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

    context "when there are page views for the user" do
      # Create three page views:
      # - page_view1: time tracked 120 seconds (should be included)
      # - page_view2: time tracked 30 seconds (should be excluded)
      # - page_view3: time tracked 100 seconds (should be included)
      let!(:page_view1) do
        create(:page_view,
               user: user,
               article_id: article1.id,
               created_at: 2.hours.ago,
               time_tracked_in_seconds: 120)
      end

      let!(:page_view2) do
        create(:page_view,
               user: user,
               article_id: article2.id,
               created_at: 1.hour.ago,
               time_tracked_in_seconds: 30)
      end

      let!(:page_view3) do
        create(:page_view,
               user: user,
               article_id: article2.id,
               created_at: 30.minutes.ago,
               time_tracked_in_seconds: 100)
      end

      before do
        # Call the method under test.
        activity.set_activity!
      end

      it "sets last_activity_at to the current time" do
        expect(activity.last_activity_at).to be_within(1.second).of(Time.current)
      end

      it "stores the recently viewed articles from the user's page views" do
        expected_recently_viewed = user.page_views
                                      .order(created_at: :desc)
                                      .limit(20)
                                      .pluck(:article_id, :created_at, :time_tracked_in_seconds)
        expect(activity.recently_viewed_articles.map(&:first)).to eq(expected_recently_viewed.map(&:first))
      end

      it "selects only page views with time_tracked_in_seconds > 59 and finds the related articles" do
        expected_article_ids = [page_view1.article_id, page_view3.article_id]
        recent_articles = Article.where(id: expected_article_ids)
        expected_tags = (article1.cached_tag_list + article2.cached_tag_list).uniq.first(5)
        expected_labels = (article1.cached_label_list + article2.cached_label_list).uniq.compact.first(5)
        expected_orgs  = [article1.organization_id, article2.organization_id].uniq.compact
        expected_users = [article1.user_id, article2.user_id].uniq.compact

        expect(activity.recent_tags).to eq(expected_tags)
        expect(activity.recent_labels).to eq(expected_labels)
        expect(activity.recent_organizations).to eq(expected_orgs)
        expect(activity.recent_users).to eq(expected_users)
      end

      it "sets alltime_tags from the user's cached followed tag names" do
        expect(activity.alltime_tags).to eq(user.cached_followed_tag_names.first(10))
      end
    end

    context "when a UserActivity record already exists" do
      let!(:existing_activity) { create(:user_activity, user: user, last_activity_at: 1.day.ago) }

      before do
        # Ensure there is at least one page view so the method will update attributes.
        create(:page_view,
               user: user,
               article_id: article1.id,
               created_at: 1.hour.ago,
               time_tracked_in_seconds: 120)
        existing_activity.set_activity
      end

      it "updates the existing record instead of initializing a new one" do
        expect(existing_activity.last_activity_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end
end
