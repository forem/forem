require "rails_helper"

RSpec.describe Slack::Messengers::UserDeleted, type: :service do
  let(:user) { build(:user) }

  let(:default_params) do
    {
      name: user.name,
      user_url: URL.user(user)
    }
  end

  it "contains the correct info", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    message = job["args"].first["message"]

    expect(message).to include("self-deleted their account")
    expect(message).to include(URL.user(user))
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq("user-deleted")
    expect(job_args["username"]).to eq("user_deleted_bot")
    expect(job_args["icon_emoji"]).to eq(":scissors:")
  end
end
