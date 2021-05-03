require "rails_helper"

RSpec.describe Slack::Messengers::Feedback, type: :service do
  let(:user) { build(:user) }
  let(:default_params) do
    {
      type: "abuse-reports",
      category: "spam",
      reported_url: "http://example.com",
      message: "this is spam"
    }
  end

  def get_argument_from_last_job(argument_name)
    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job["args"].first[argument_name]
  end

  it "supports an anonymous report" do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end
  end

  it "contains user's details", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params.merge(user: user))
    end

    message = get_argument_from_last_job("message")

    expect(message).to include(user.username)
    expect(message).to include(URL.user(user))
    expect(message).to include(user.email)
  end

  it "contains report information", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params.merge(user: user))
    end

    message = get_argument_from_last_job("message")
    url = URL.url(
      Rails.application.routes.url_helpers.admin_reports_path,
    )

    [
      url, user.email, default_params[:category], default_params[:reported_url]
    ].each do |value|
      expect(message).to include(value)
    end
  end

  it "messages the proper channel with the proper username" do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    channel = get_argument_from_last_job("channel")
    expect(channel).to eq(default_params[:type])

    username = get_argument_from_last_job("username")
    expect(username).to eq("#{default_params[:type]}_bot")
  end

  it "uses the cry emoji for abuse reports" do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params.merge(type: "abuse-reports"))
    end

    icon_emoji = get_argument_from_last_job("icon_emoji")
    expect(icon_emoji).to include(":cry:")
  end

  it "uses the robot face emoji for other reports" do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params.merge(type: "other"))
    end

    icon_emoji = get_argument_from_last_job("icon_emoji")
    expect(icon_emoji).not_to include(":cry:")
    expect(icon_emoji).to include(":robot_face:")
  end
end
