require "rails_helper"

RSpec.describe Slack::Messengers::CommentUserWarned, type: :service do
  let(:comment) { create(:comment) }
  let(:user) { comment.user }

  let(:default_params) { { comment: comment } }

  it "does not message slack for a comment with a regular user" do
    sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
      described_class.call(comment: build(:comment, user: build(:user)))
    end
  end

  context "when the uesr has been warned" do
    before do
      user.add_role(:warned)
    end

    it "contains the correct info", :aggregate_failures do
      sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
        described_class.call(**default_params)
      end

      job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
      message = job["args"].first["message"]

      internal_user_url = URL.url(
        Rails.application.routes.url_helpers.admin_user_path(user),
      )

      expect(message).to include(URL.comment(comment))
      expect(message).to include(comment.body_markdown.truncate(300))
      expect(message).to include(user.username)
      expect(message).to include(internal_user_url)
    end

    it "messages the proper channel with the proper username and emoji", :aggregate_failures do
      sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
        described_class.call(**default_params)
      end

      job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
      job_args = job["args"].first

      expect(job_args["channel"]).to eq("warned-user-comments")
      expect(job_args["username"]).to eq("sloan_watch_bot")
      expect(job_args["icon_emoji"]).to eq(":sloan:")
    end
  end
end
