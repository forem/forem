require "rails_helper"

RSpec.describe Slack::Messengers::PotentialSpammer, type: :service do
  let(:user) { build(:user) }

  let(:default_params) { { user: user } }

  it "contains the correct info", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    message = job["args"].first["message"]

    expect(message).to include(URL.user(user))
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq("potential-spam")
    expect(job_args["username"]).to eq("spam_account_checker_bot")
    expect(job_args["icon_emoji"]).to eq(":exclamation:")
  end
end
