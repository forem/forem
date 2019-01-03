require "rails_helper"

RSpec.describe "internal/users", type: :request do
  context "when banishing user" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:article) { create(:article, user: user) }
    let(:article2) { create(:article, user: user2) }

    before do
      sign_in super_admin
      # Delayed::Worker.delay_jobs = true
      # Delayed::Worker.destroy_failed_jobs = false
    end

    after do
      # Delayed::Worker.delay_jobs = false
    end

    def banish_user
      post "/internal/users/#{user.id}/banish"
      # Delayed::Worker.new(quiet: true).work_off
      user.reload
    end

    def dependents_for_offending_user_article
      # create user2 comment on offending user article
      comment = create(:comment, commentable_type: "Article", commentable: article, user: user2)
      # create user3 reaction to user2 comment
      create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
      # create user3 comment response to user2 comment
      comment2 = create(:comment, commentable_type: "Article", commentable: article, user: user2, ancestry: comment.id)
      # create user2 reaction to user3 comment response
      Reaction.create(reactable: comment2, reactable_type: "Comment", user: user2)
      # create user3 reaction to offending article
      create(:reaction, reactable: article, reactable_type: "Article", user: user3, category: "like")
    end

    def offender_activity_on_other_content
      # offender reacts to user2 article
      create(:reaction, reactable: article2, reactable_type: "Article", user: user)
      # offender comments on user2 article
      comment = create(:comment, commentable_type: "Article", commentable: article2, user: user)
      # user3 reacts to offender comment
      create(:reaction, reactable: comment, reactable_type: "Comment", user: user3)
    end

    it "deletes all dependents from offending user article" do
      dependents_for_offending_user_article
      offender_activity_on_other_content
      banish_user
      expect(user.username).to include("spam_")
      expect(user.articles.count).to eq(0)
      expect(Comment.count).to eq(0)
      expect(Reaction.count).to eq(0)
      expect(user.currently_learning).to eq("")
      expect(user.banned).to eq(true)
      expect(Note.count).to eq(1)
    end

    xit "works" do
      create(:reaction, reactable: article, reactable_type: "Article", user: user)
      create(:comment, commentable_type: "Article", commentable: article, user: user)
      Delayed::Worker.new(quiet: false).work_off
      user.currently_learning = "blah blah balh"
      banish_user
      expect(user.username).to include("spam_")
      expect(Article.count).to eq(0)
      expect(Comment.count).to eq(0)
      expect(Reaction.count).to eq(0)
      expect(user.currently_learning).to eq("")
      expect(user.banned).to eq(true)
      expect(Note.count).to eq(1)
    end

  end
end
