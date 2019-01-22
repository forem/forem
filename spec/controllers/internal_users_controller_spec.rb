require "rails_helper"

RSpec.describe "internal/users", type: :request do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:article) { create(:article, user: user) }
  let(:article2) { create(:article, user: user2) }

  before do
    sign_in super_admin
    user
    user2
    Delayed::Worker.delay_jobs = true
    dependents_for_offending_user_article
    offender_activity_on_other_content
  end

  after do
    Delayed::Worker.delay_jobs = false
  end

  def dependents_for_offending_user_article
    # create user2 comment on offending user article
    comment = create(:comment, commentable_type: "Article", commentable: article, user: user2)
    # create user3 reaction to user2 comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    # create user3 comment response to user2 comment
    comment2 = create(:comment, commentable_type: "Article", commentable: article, user: user3, ancestry: comment.id)
    # create user2 reaction to user3 comment response
    create(:reaction, reactable: comment2, reactable_type: "Comment", user: user2)
    # create user3 reaction to offending article
    create(:reaction, reactable: article, reactable_type: "Article", user: user3, category: "like")
    Delayed::Worker.new(quiet: true).work_off
  end

  def offender_activity_on_other_content
    # offender reacts to user2 article
    create(:reaction, reactable: article2, reactable_type: "Article", user: user)
    # offender comments on user2 article
    comment = create(:comment, commentable_type: "Article", commentable: article2, user: user)
    # user3 reacts to offender comment
    create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    Delayed::Worker.new(quiet: true).work_off
  end

  context "when deleting user" do
    def create_mention
      comment = create(
        :comment,
        body_markdown: "Hello @#{user.username}, you are cool.",
        user_id: user2.id,
        commentable_id: article2.id,
      )
      Mention.create_all_without_delay(comment)
    end

    def create_mutual_follows
      user.follow(user3)
      follow = user3.follow(user)
      Notification.send_new_follower_notification_without_delay(follow)
    end

    before do
      sign_in super_admin
      create_mutual_follows
      # create_mention
      create(:badge_achievement, rewarder_id: 1, rewarding_context_message: "yay", user_id: user.id)
      Delayed::Worker.new(quiet: true).work_off
    end

    it "raises a 'record not found' error after deletion" do
      post "/internal/users/#{user.id}/full_delete"
      # binding.pry
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context "when banning from mentorship" do
    before do
      user.update(offering_mentorship: true, mentor_description: "I want to be a mentor")
    end

    it "adds banned from mentorship role" do
      put "/internal/users/#{user.id}", params: { user: { ban_from_mentorship: "1", note_for_mentorship_ban: "banned" } }
      expect(user.roles.first.name).to eq("banned_from_mentorship")
    end

    it "returns user to good standing if unbanned" do
      put "/internal/users/#{user.id}", params: { user: { good_standing_user: "1" } }
      expect(user.roles.count).to eq(0)
    end
  end

  context "when banishing user" do
    def banish_user
      post "/internal/users/#{user.id}/banish"
      Delayed::Worker.new(quiet: true).work_off
      user.reload
    end

    it "reassigns username and removes profile info" do
      user.currently_hacking_on = "currently hackin on !!!!!!!!!!!!"
      user.save
      banish_user
      expect(user.currently_hacking_on).to eq("")
      expect(user.username).to include("spam_")
    end

    it "adds banned role" do
      banish_user
      expect(user.roles.last.name).to eq("banned")
      expect(Note.count).to eq(1)
    end

    it "deletes user content" do
      banish_user
      expect(user.reactions.count).to eq(0)
      expect(user.comments.count).to eq(0)
      expect(user.articles.count).to eq(0)
    end

    it "removes all follow relationships" do
      user.follow(user2)
      banish_user
      expect(user.follows.count).to eq(0)
    end
  end
end
