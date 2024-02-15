require "rails_helper"

RSpec.describe Articles::Feeds do
  describe "NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS" do
    it "sets NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS to ApplicationConfig" do
      allow(ApplicationConfig).to receive(:[])
        .with("NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS").and_return(4)
      expect(described_class.number_of_hours_to_offset_users_latest_article_views).to eq(4)
    end

    it "returns default 18 when ApplicationConfig is not defined" do
      expect(described_class.number_of_hours_to_offset_users_latest_article_views).to eq(18)
    end
  end

  describe ".oldest_published_at_to_consider_for" do
    subject(:function_call) { described_class.oldest_published_at_to_consider_for(user: user) }

    context "when the given user is nil" do
      let(:user) { nil }

      it "returns Article::Feeds::DEFAULT_DAYS_SINCE_PUBLISHED days ago" do
        # Why the to_date coercion?  Because Integer.days.ago is an
        # ActiveSupport::TimeWithZone variable that includes
        # microseconds, and in the time between the function_call and
        # the expectation test, there's a few microseconds that passed
        # (based on your processor).  In theory, this test might fail
        # if someone ran the test right around the stroke of midnight.
        expect(function_call.to_date).to eq(Articles::Feeds::DEFAULT_DAYS_SINCE_PUBLISHED.days.ago.to_date)
      end
    end

    context "when the given user has no page views" do
      let(:user) { instance_double(User) }

      before do
        allow(user).to receive(:page_views).and_return(nil)
      end

      it { is_expected.to be_a ActiveSupport::TimeWithZone }
    end

    context "when the user has page views" do
      let(:user) { instance_double(User) }
      let(:page_viewed_at) { Time.current }
      let(:expected_result) do
        page_viewed_at - described_class.number_of_hours_to_offset_users_latest_article_views.hours
      end

      before do
        # This is a distinct code smell.  The other option is adding a
        # method to user and perhaps to page views and then testing
        # delegation.  This is, instead, an ActiveRecord call chain,
        # so I'm going to ask that we accept this smell to ease
        # testing.
        # rubocop:disable RSpec/MessageChain
        allow(user).to receive_message_chain(:page_views, :second_to_last, :created_at).and_return(page_viewed_at)
        # rubocop:enable RSpec/MessageChain
      end

      it { is_expected.to eq(expected_result) }
    end
  end
end
