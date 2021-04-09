require "rails_helper"

RSpec.describe Slack::Messengers::ArticlePublished, type: :service do
  let(:article) do
    build(:article).tap do |article|
      article.title = "Awesome article"
      article.published = true
      article.published_at = Time.current
    end
  end

  let(:default_params) { { article: article } }

  it "does not message slack for a draft article" do
    sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
      article = build(:article, published: false)
      described_class.call(article: article)
    end
  end

  it "does not message slack for an article that was published long ago" do
    sidekiq_assert_no_enqueued_jobs(only: Slack::Messengers::Worker) do
      article = build(:article).tap do |art|
        art.published = true
        art.published_at = 1.minute.ago
      end
      described_class.call(article: article)
    end
  end

  it "contains the correct info", :aggregate_failures do
    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    message = job["args"].first["message"]

    expect(message).to include(article.title)
    expect(message).to include(URL.article(article))
  end

  it "messages the proper channel with the proper username and emoji", :aggregate_failures do
    channel = "test-channel"
    # [forem-fix] Remove channel name from SiteConfig
    allow(SiteConfig).to receive(:article_published_slack_channel).and_return(channel)

    sidekiq_assert_enqueued_jobs(1, only: Slack::Messengers::Worker) do
      described_class.call(**default_params)
    end

    job = sidekiq_enqueued_jobs(worker: Slack::Messengers::Worker).last
    job_args = job["args"].first

    expect(job_args["channel"]).to eq(channel)
    expect(job_args["username"]).to eq("article_bot")
    expect(job_args["icon_emoji"]).to eq(":writing_hand:")
  end
end
