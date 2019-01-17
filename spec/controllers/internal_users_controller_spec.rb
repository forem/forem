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
    it "raises a 'record not found' error after deletion" do
      post "/internal/users/#{user.id}/full_delete"
      expect { User.find(user.id) }.to raise_exception(ActiveRecord::RecordNotFound)
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
