require "rails_helper"

RSpec.describe Slack::Messengers::Note, type: :service do
  let(:default_params) do
    {
      author_name: "bob",
      status: "Open",
      type: "abuse-reports",
      report_id: 1,
      message: "test note"
    }
  end

  it "contains the correct info", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    message = job["args"].first["message"]

    expect(message).to include(default_params[:author_name])
    expect(message).to include(default_params[:status])
    url = URL.url(
      Rails.application.routes.url_helpers.admin_report_path(
        default_params[:report_id],
      ),
    )
    expect(message).to include(url)
    expect(message).to include(default_params[:message])
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq(default_params[:type])
    expect(job_args["username"]).to eq("new_note_bot")
    expect(job_args["icon_emoji"]).to eq(":memo:")
  end
end
