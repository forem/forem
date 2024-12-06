# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::AtomGoogleAlertsEntry do
  before do
    feed = Feedjira::Parser::AtomGoogleAlerts.parse sample_google_alerts_atom_feed
    @entry = feed.entries.first
  end

  it "parses the title" do
    expect(@entry.title).to eq "Report offers Prediction of Automotive Slack Market by Top key players like Haldex, Meritor, Bendix ..."
    expect(@entry.raw_title).to eq "Report offers Prediction of Automotive <b>Slack</b> Market by Top key players like Haldex, Meritor, Bendix ..."
    expect(@entry.title_type).to eq "html"
  end

  it "parses the url" do
    expect(@entry.url).to eq "https://www.aglobalmarketresearch.com/report-offers-prediction-of-automotive-slack-market-by-top-key-players-like-haldex-meritor-bendix-mei-wabco-accuride-stemco-tbk-febi-aydinsan/"
  end

  it "parses the content" do
    expect(@entry.content).to eq "Automotive <b>Slack</b> Market reports provides a comprehensive overview of the global market size and share. It provides strategists, marketers and senior&nbsp;..."
  end

  it "parses the published date" do
    published = Time.parse_safely "2019-07-10T11:53:37Z"
    expect(@entry.published).to eq published
  end

  it "parses the updated date" do
    updated = Time.parse_safely "2019-07-10T11:53:37Z"
    expect(@entry.updated).to eq updated
  end
end
