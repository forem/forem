require "rails_helper"

RSpec.describe "internal/users", type: :request do
  context "when banishing user" do
    let(:user) { create(:user) }
    let(:article) { create(:article, user_id: user.id) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:comment) { create(:comment, commentable_type: "Article", commentable_id: article.id, user_id: user.id) }
    let(:reaction) { create(:reaction, reactable: article, reactable_type: "Article", user_id: user.id) }

    before do
      sign_in super_admin
      @count ||= 1
      Delayed::Worker.delay_jobs = -> (job) {
        # puts job.payload_object.method_name
        true
      }
      Delayed::Worker.destroy_failed_jobs = false
    end

    after do
      Delayed::Worker.delay_jobs = false
    end

    def banish_user
      post "/internal/users/#{user.id}/banish"
      Delayed::Worker.new(quiet: false).work_off
    end

    it "all delayed jobs pass", focus: true do
      reaction
      Delayed::Worker.new(quiet: false).work_off
      banish_user
      if Delayed::Job.where("failed_at IS NOT NULL").count > 0
        class_name = YAML.load(Delayed::Job.last.handler).object.class.name
        method = YAML.load(Delayed::Job.last.handler).method_name
        puts class_name + " " +  method.to_s
      end
      expect(Delayed::Job.where("failed_at IS NOT NULL").count).to eq(0)
      expect(true).to eq(false)
    end
  end
end
