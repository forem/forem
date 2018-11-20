require "rails_helper"

RSpec.describe "internal/users", type: :request do
  context "when banishing user" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user: user) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:comment) { create(:comment, commentable_type: "Article", commentable: article, user: user) }
    let(:article2) { create(:article, user: super_admin) }
    let(:comment2) { create(:comment, commentable_type: "Article", commentable: article2, user: super_admin) }
    let(:comment3) { create(:comment, commentable_type: "Article", commentable: article2, user: super_admin) }
    let(:comment4) { create(:comment, commentable_type: "Comment", commentable: comment, user: user) }
    let(:reaction) { create(:reaction, reactable: article, reactable_type: "Article", user: user) }

    before do
      sign_in super_admin
      Delayed::Worker.delay_jobs = true
      Delayed::Worker.destroy_failed_jobs = false
    end

    after do
      Delayed::Worker.delay_jobs = false
    end

    def banish_user
      user
      Delayed::Worker.new(quiet: true).work_off
      post "/internal/users/#{user.id}/banish"
      Delayed::Worker.new(quiet: true).work_off
      user.reload
    end

    def create_dependents
      reaction
      comment
      comment2
      comment3
    end

    it "all delayed jobs pass" do
      create_dependents
      user.follow(super_admin)
      Delayed::Worker.new(quiet: true).work_off
      banish_user
      # if Delayed::Job.where("failed_at IS NOT NULL").count > 0
      #   class_name = YAML.safe_load(Delayed::Job.last.handler).object.class.name
      #   method = YAML.safe_load(Delayed::Job.last.handler).method_name
      #   puts class_name + " " + method.to_s
      # end
      expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
      expect(user.old_username).to eq(nil)
      expect(user.twitter_username).to eq("")
    end

    context "when an offender has no data" do
      it "works" do
        banish_user
        expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
        expect(user.old_username).to eq(nil)
        expect(user.twitter_username).to eq("")
      end
    end

    context "when an offender is already banned" do
      it "works" do
        banish_user
        expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
        expect(user.old_username).to eq(nil)
        expect(user.github_username).to eq("")
      end
    end

    context "when an offender has article and comments on their article"
    context "when an offender has comments on someone else's article"
    context "when an offender has comments on other comments"
  end
end
