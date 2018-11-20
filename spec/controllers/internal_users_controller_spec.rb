require "rails_helper"

RSpec.describe "internal/users", type: :request do
  context "when banishing user" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:article2) { create(:article, user: super_admin) }

    before do
      sign_in super_admin
      Delayed::Worker.delay_jobs = true
      Delayed::Worker.destroy_failed_jobs = false
    end

    after do
      Delayed::Worker.delay_jobs = false
    end

    def banish_user
      post "/internal/users/#{user.id}/banish"
      Delayed::Worker.new(quiet: false).work_off
      user.reload
    end

    def create_dependents
      # Article 1
      create(:reaction, reactable: article, reactable_type: "Article", user: user)
      parent_comment = create(:comment, commentable_type: "Article", commentable: article, user: user)
      create(:comment, commentable_type: "Article", commentable: article, user: user, parent: parent_comment)

      # Article 2 written by super_admin
      create(:reaction, reactable: article2, reactable_type: "Article", user: user)
      parent_comment2 = create(:comment, commentable_type: "Article", commentable: article2, user: user)
      create(:comment, commentable_type: "Article", commentable: article2, user: super_admin, parent: parent_comment2)

      user.follow(super_admin)

      Delayed::Worker.new(quiet: true).work_off
    end

    context "when offender is a spam user" do
      before do
        create(:reaction, reactable: article, reactable_type: "Article", user: user)
        create(:comment, commentable_type: "Article", commentable: article, user: user)
        Delayed::Worker.new(quiet: true).work_off
      end

      it "works" do
        banish_user
        expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
        expect(user.old_username).to eq(nil)
        expect(user.twitter_username).to eq("")
      end
    end

    xcontext "when offender has rich activity " do
      it "works" do
        create_dependents
        banish_user
        # failed = Delayed::Job.where("failed_at IS NOT NULL").first
        # failed = YAML.load(failed.handler) if failed
        # binding.pry
        expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
        expect(user.old_username).to eq(nil)
        expect(user.twitter_username).to eq("")
      end
    end
  end
end
