require "rails_helper"

RSpec.describe Slack::Messengers::Sponsorship, type: :service do
  let(:user) { build(:user) }
  let(:organization) { build(:organization) }
  let(:tag) { build(:tag) }

  let(:default_params) do
    {
      user: user,
      organization: organization,
      level: "gold"
    }
  end

  def get_argument_from_last_job(argument_name)
    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job["args"].first[argument_name]
  end

  it "contains the correct info for a regular sponsorship", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    message = get_argument_from_last_job("message")

    expect(message).to include(user.username)
    expect(message).to include(default_params[:level])
    expect(message).to include(organization.username)
  end

  it "contains the correct info for a tag sponsorship", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params.merge(level: "tag", tag: tag))
    end

    message = get_argument_from_last_job("message")

    expect(message).to include(user.username)
    expect(message).not_to include(default_params[:level])
    expect(message).to include(tag.name)
    expect(message).to include(organization.username)
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq("incoming-partners")
    expect(job_args["username"]).to eq("media_sponsor")
    expect(job_args["icon_emoji"]).to eq(":partyparrot:")
  end
end
