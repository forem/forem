require "rails_helper"

RSpec.describe Comments::CommunityWellnessQuery, type: :query do
  include ActionView::Helpers::DateHelper

  let!(:articles) { create_list(:article, 4) }
  let(:mod) { create(:user, :trusted) }
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }

  context "when multiple users match criteria" do
    before do
      # User 1 - week 1
      create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 3.days.ago)
      create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 4.days.ago)
      # User 1 - week 2
      create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 8.days.ago)
      create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 11.days.ago)

      # User 2 - week 1
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 1.day.ago)
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 6.days.ago)
      # User 1 - week 2
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 9.days.ago)
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 13.days.ago)
      # User 1 - week 3
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 17.days.ago)
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 17.days.ago)
      create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 18.days.ago)
    end

    it "returns the correct data structure (array of hashes w/ correct keys)" do
      result = described_class.call
      p "RESULT: #{result}"
      Comment.all.each do |comment|
        p "[#{comment.user_id}] #{time_ago_in_words(comment.created_at)}"
      end

      expect(result).to be_instance_of(Array)
      expect(result.count).to eq(2)

      result.each do |hash|
        expect(hash["user_id"]).to be_instance_of(String)
        expect(hash["serialized_weeks_ago"]).to be_instance_of(String)
        expect(hash["serialized_comment_counts"]).to be_instance_of(String)
      end
    end

    # it "returns users with correct data on their corresponding hash" do
    #   result = described_class.call
    #
    #   result_user_ids = result.map { |hash| hash['user_id'] }
    #   expect(result_user_ids).to contain_exactly([user1.id, user2.id])
    #
    #   index1 = result.index { |hash| hash['user_id'] == user1.id }
    #   expect(result[index1]['serialized_weeks_ago']).to eq('1,2')
    #   expect(result[index1]['serialized_comment_counts']).to eq('2,2')
    #
    #   index2 = result.index { |hash| hash['user_id'] == user2.id }
    #   expect(result[index2]['serialized_weeks_ago']).to eq('1,2,3')
    #   expect(result[index2]['serialized_comment_counts']).to eq('2,2,3')
    # end
  end

  # context "a user matches criteria and another fails because of mod reactions" do
  #   before do
  #     # User 1 - week 1
  #     create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 3.days.ago)
  #     create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 4.days.ago)
  #     # User 1 - week 2
  #     create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 8.days.ago)
  #     create(:comment, commentable: articles.sample, user_id: user1.id, created_at: 11.days.ago)
  #
  #     # User 2 - week 1
  #     create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 1.day.ago)
  #     create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 6.days.ago)
  #     # User 1 - week 2
  #     create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 9.days.ago)
  #     flagged_comment = create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 13.days.ago)
  #     create(:reaction, :vomit_reaction, user: mod)
  #     # User 1 - week 3
  #     create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 17.days.ago)
  #     create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 17.days.ago)
  #     create(:comment, commentable: articles.sample, user_id: user2.id, created_at: 18.days.ago)
  #   end
  #
  #   it "doesn't include user that failed to meet criteria" do
  #     # TODO
  #   end
  #
  #   it "matches the correct comment count for each week in result hash" do
  #     # TODO
  #   end
  # end
end
