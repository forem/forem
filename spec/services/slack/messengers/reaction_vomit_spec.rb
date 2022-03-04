require "rails_helper"

RSpec.describe Slack::Messengers::ReactionVomit, type: :service do
  let(:reaction) { build(:reaction, category: :vomit, user: build(:user)) }
  let(:user) { reaction.user }

  let(:default_params) { { reaction: reaction } }

  it "does not message slack for a like reaction" do
    sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
      reaction = build(:reaction, category: :like)
      described_class.call(reaction: reaction)
    end
  end

  it "contains the correct info", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    message = job["args"].first["message"]

    expect(message).to include(user.name)
    expect(message).to include(URL.user(user))
    expect(message).to include(reaction.category)
    expect(message).to include(URL.reaction(reaction))
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq("abuse-reports")
    expect(job_args["username"]).to eq("abuse_bot")
    expect(job_args["icon_emoji"]).to eq(":cry:")
  end
end
