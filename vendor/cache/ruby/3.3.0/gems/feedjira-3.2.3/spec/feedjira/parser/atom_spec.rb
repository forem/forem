# frozen_string_literal: true

require "spec_helper"

module Feedjira
  module Parser
    describe "#will_parse?" do
      it "returns true for an atom feed" do
        expect(Atom).to be_able_to_parse(sample_atom_feed)
      end

      it "returns false for an rdf feed" do
        expect(Atom).not_to be_able_to_parse(sample_rdf_feed)
      end

      it "returns false for an rss feedburner feed" do
        expect(Atom).not_to be_able_to_parse(sample_rss_feed_burner_feed)
      end

      it "returns true for an atom feed that has line breaks in between attributes in the <feed> node" do
        expect(Atom).to be_able_to_parse(sample_atom_feed_line_breaks)
      end
    end

    describe "parsing" do
      before do
        @feed = Atom.parse(sample_atom_feed)
      end

      it "parses the title" do
        expect(@feed.title).to eq "Amazon Web Services Blog"
      end

      it "parses the description" do
        description = "Amazon Web Services, Products, Tools, and Developer Information..."
        expect(@feed.description).to eq description
      end

      it "parses the icon url" do
        feed_with_icon = Atom.parse(load_sample("SamRuby.xml"))
        expect(feed_with_icon.icon).to eq "../favicon.ico"
      end

      it "parses the url" do
        expect(@feed.url).to eq "http://aws.typepad.com/aws/"
      end

      it "parses the url even when it doesn't have the type='text/html' attribute" do
        xml = load_sample "atom_with_link_tag_for_url_unmarked.xml"
        feed = Atom.parse xml
        expect(feed.url).to eq "http://www.innoq.com/planet/"
      end

      it "parses the feed_url even when it doesn't have the type='application/atom+xml' attribute" do
        feed = Atom.parse(load_sample("atom_with_link_tag_for_url_unmarked.xml"))
        expect(feed.feed_url).to eq "http://www.innoq.com/planet/atom.xml"
      end

      it "parses the feed_url" do
        expect(@feed.feed_url).to eq "http://aws.typepad.com/aws/atom.xml"
      end

      it "parses no hub urls" do
        expect(@feed.hubs.count).to eq 0
      end

      it "parses the hub urls" do
        feed_with_hub = Atom.parse(load_sample("SamRuby.xml"))
        expect(feed_with_hub.hubs.count).to eq 1
        expect(feed_with_hub.hubs.first).to eq "http://pubsubhubbub.appspot.com/"
      end

      it "parses entries" do
        expect(@feed.entries.size).to eq 10
      end
    end

    describe "preprocessing" do
      it "retains markup in xhtml content" do
        Atom.preprocess_xml = true

        feed = Atom.parse sample_atom_xhtml_feed
        entry = feed.entries.first

        expect(entry.raw_title).to match(/<i/)
        expect(entry.title).to eq("Sentry Calming Collar for dogs")
        expect(entry.title_type).to eq("xhtml")
        expect(entry.summary).to match(/<b/)
        expect(entry.content).to match(/\A<p/)
      end

      it "does not duplicate content when there are divs in content" do
        Atom.preprocess_xml = true

        feed = Atom.parse sample_duplicate_content_atom_feed
        content = Nokogiri::HTML(feed.entries[1].content)
        expect(content.css("img").length).to eq 11
      end
    end

    describe "parsing url and feed_url" do
      before do
        @feed = Atom.parse(sample_atom_middleman_feed)
      end

      it "parses url" do
        expect(@feed.url).to eq "http://feedjira.com/blog"
      end

      it "parses feed_url" do
        expect(@feed.feed_url).to eq "http://feedjira.com/blog/feed.xml"
      end

      it "does not parse links without the rel='self' attribute as feed_url" do
        xml = load_sample "atom_simple_single_entry.xml"
        feed = Atom.parse xml
        expect(feed.feed_url).to be_nil
      end

      it "does not parse links with the rel='self' attribute as url" do
        xml = load_sample "atom_simple_single_entry_link_self.xml"
        feed = Atom.parse xml
        expect(feed.url).to be_nil
      end
    end
  end
end
