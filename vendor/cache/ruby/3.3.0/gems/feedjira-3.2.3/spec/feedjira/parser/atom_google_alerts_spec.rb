# frozen_string_literal: true

require "spec_helper"

module Feedjira
  module Parser
    describe "#able_to_parse?" do
      it "returns true for a Google Alerts atom feed" do
        expect(AtomGoogleAlerts).to be_able_to_parse(sample_google_alerts_atom_feed)
      end

      it "returns false for an rdf feed" do
        expect(AtomGoogleAlerts).not_to be_able_to_parse(sample_rdf_feed)
      end

      it "returns false for a regular atom feed" do
        expect(AtomGoogleAlerts).not_to be_able_to_parse(sample_atom_feed)
      end

      it "returns false for a feedburner atom feed" do
        expect(AtomGoogleAlerts).not_to be_able_to_parse(sample_feedburner_atom_feed)
      end
    end

    describe "parsing" do
      before do
        @feed = AtomGoogleAlerts.parse(sample_google_alerts_atom_feed)
      end

      it "parses the title" do
        expect(@feed.title).to eq "Google Alert - Slack"
      end

      it "parses the descripton" do
        expect(@feed.description).to be_nil
      end

      it "parses the url" do
        expect(@feed.url).to eq "https://www.google.com/alerts/feeds/04175468913983673025/4428013283581841004"
      end

      it "parses the feed_url" do
        expect(@feed.feed_url).to eq "https://www.google.com/alerts/feeds/04175468913983673025/4428013283581841004"
      end

      it "parses entries" do
        expect(@feed.entries.size).to eq 20
      end
    end

    describe "preprocessing" do
      it "retains markup in xhtml content" do
        AtomGoogleAlerts.preprocess_xml = true

        feed = AtomGoogleAlerts.parse sample_google_alerts_atom_feed
        entry = feed.entries.first

        expect(entry.content).to include("<b>Slack</b>")
      end
    end
  end
end
