# frozen_string_literal: true

require "spec_helper"

RSpec.describe Feedjira do
  describe ".parse" do
    context "when the parser is specified" do
      it "parses an rss feed" do
        parser = described_class.parser_for_xml(sample_rss_feed)
        feed = described_class.parse(sample_rss_feed, parser: parser)

        expect(feed.title).to eq "Tender Lovemaking"
        published = Time.parse_safely "Thu Dec 04 17:17:49 UTC 2008"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 10
      end
    end

    context "when there's an available parser" do
      it "parses an rdf feed" do
        feed = described_class.parse(sample_rdf_feed)
        expect(feed.title).to eq "HREF Considered Harmful"
        published = Time.parse_safely("Tue Sep 02 19:50:07 UTC 2008")
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 10
      end

      it "parses an rss feed" do
        feed = described_class.parse(sample_rss_feed)
        expect(feed.title).to eq "Tender Lovemaking"
        published = Time.parse_safely "Thu Dec 04 17:17:49 UTC 2008"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 10
      end

      it "parses an atom feed" do
        feed = described_class.parse(sample_atom_feed)
        expect(feed.title).to eq "Amazon Web Services Blog"
        published = Time.parse_safely "Fri Jan 16 18:21:00 UTC 2009"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 10
      end

      it "parses an feedburner atom feed" do
        feed = described_class.parse(sample_feedburner_atom_feed)
        expect(feed.title).to eq "Paul Dix Explains Nothing"
        published = Time.parse_safely "Thu Jan 22 15:50:22 UTC 2009"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 5
      end

      it "parses an itunes feed" do
        feed = described_class.parse(sample_itunes_feed)
        expect(feed.title).to eq "All About Everything"
        published = Time.parse_safely "Wed, 15 Jun 2005 19:00:00 GMT"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 3
      end

      it "parses an itunes feedburner feed" do
        feed = described_class.parse(sample_itunes_feedburner_feed)
        expect(feed.title).to eq "Welcome to Night Vale"
        published = Time.parse_safely "2023-09-22 16:30:15 UTC"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 3
        url = "https://www.podtrac.com/pts/redirect.mp3/dovetail.prxu.org/_/126/e3dafc45-a202-42d0-a55b-216e733a2d7a/2023_09_17_BTS_Episode_EXCERPT_v2.mp3"
        expect(feed.entries.first.enclosure_url).to eq url
      end

      it "with nested dc:identifier it does not overwrite entry_id" do
        feed = described_class.parse(sample_rss_feed_huffpost_ca)
        expect(feed.title.strip).to eq "HuffPost Canada - Athena2 - All Posts"
        expect(feed.entries.size).to eq 2
        expect(feed.entries.first.id).to eq "23246627"
        expect(feed.entries.last.id.strip).to eq "1"
      end

      it "does not fail if multiple published dates exist and some are unparseable" do
        expect(described_class.logger).to receive(:debug).twice

        feed = described_class.parse(sample_invalid_date_format_feed)
        expect(feed.title).to eq "Invalid date format feed"
        published = Time.parse_safely "Mon, 16 Oct 2017 15:10:00 GMT"
        expect(feed.entries.first.published).to eq published
        expect(feed.entries.size).to eq 2
      end
    end

    context "when there's no available parser" do
      it "raises described_class::NoParserAvailable" do
        expect do
          described_class.parse("I'm an invalid feed")
        end.to raise_error(described_class::NoParserAvailable)
      end
    end

    it "parses an feedburner rss feed" do
      feed = described_class.parse(sample_rss_feed_burner_feed)
      expect(feed.title).to eq "TechCrunch"
      published = Time.parse_safely "Wed Nov 02 17:25:27 UTC 2011"
      expect(feed.entries.first.published).to eq published
      expect(feed.entries.size).to eq 20
    end

    it "parses an RSS feed with an a10 namespace" do
      feed = described_class.parse(sample_rss_feed_with_a10_namespace)
      expect(feed.url).to eq "http://www.example.com/"
      expect(feed.entries.first.url).to eq "http://www.example.com/5"
      expect(feed.entries.first.updated).to eq Time.parse_safely("2020-05-14T10:00:18Z")
      expect(feed.entries.first.author).to eq "John Doe"
      expect(feed.entries.size).to eq 5
    end
  end

  describe ".parser_for_xml" do
    it "with Google Docs atom feed it returns the GoogleDocsAtom parser" do
      xml = sample_google_docs_list_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::GoogleDocsAtom
    end

    it "with an atom feed it returns the Atom parser" do
      xml = sample_atom_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::Atom
    end

    it "with an atom feedburner feed it returns the AtomFeedBurner parser" do
      xml = sample_feedburner_atom_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::AtomFeedBurner
    end

    it "with an rdf feed it returns the RSS parser" do
      xml = sample_rdf_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::RSS
    end

    it "with an rss feedburner feed it returns the RSSFeedBurner parser" do
      xml = sample_rss_feed_burner_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::RSSFeedBurner
    end

    it "with an rss 2.0 feed it returns the RSS parser" do
      xml = sample_rss_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::RSS
    end

    it "with an itunes feed it returns the RSS parser" do
      xml = sample_itunes_feed
      actual_parser = described_class.parser_for_xml(xml)
      expect(actual_parser).to eq described_class::Parser::ITunesRSS
    end

    context "when parsers are configured" do
      it "does not use default parsers" do
        xml = "Atom asdf"
        new_parser = Class.new do
          def self.able_to_parse?(_xml)
            true
          end
        end

        described_class.configure { |config| config.parsers = [new_parser] }

        parser = described_class.parser_for_xml(xml)
        expect(parser).to eq(new_parser)

        described_class.reset_configuration!
      end
    end
  end
end
