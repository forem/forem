# frozen_string_literal: true

require "spec_helper"

describe Feedjira::FeedUtilities do
  before do
    @klass = Class.new do
      include SAXMachine
      include Feedjira::FeedUtilities
    end
  end

  describe "preprocessing" do
    context "when the flag is not set" do
      it "does not call the preprocessing method" do
        @klass.preprocess_xml = false
        expect(@klass).not_to receive :preprocess
        @klass.parse sample_rss_feed
      end
    end

    context "when the flag is set" do
      it "calls the preprocessing method" do # rubocop:todo RSpec/NoExpectationExample
        @klass.preprocess_xml = true
        allow(@klass).to receive(:preprocess).and_return sample_rss_feed
        @klass.parse sample_rss_feed
      end
    end
  end

  describe "when configured to strip whitespace" do
    context "when strip_whitespace config is true" do
      it "strips all XML whitespace" do
        Feedjira.configure { |config| config.strip_whitespace = true }

        expect(@klass.strip_whitespace("\nfoobar\n")).to eq("foobar")

        Feedjira.configure { |config| config.strip_whitespace = false }
      end
    end

    context "when strip_whitespace is configured false" do
      it "lstrips XML whitespace" do
        expect(@klass.strip_whitespace("\nfoobar\n")).to eq("foobar\n")
      end
    end
  end

  describe "instance methods" do
    it "provides an updated? accessor" do
      feed = @klass.new
      expect(feed).not_to be_updated
      feed.updated = true
      expect(feed).to be_updated
    end

    it "provides a new_entries accessor" do
      feed = @klass.new
      expect(feed.new_entries).to eq []
      feed.new_entries = [:foo]
      expect(feed.new_entries).to eq [:foo]
    end

    it "provides an etag accessor" do
      feed = @klass.new
      feed.etag = "foo"
      expect(feed.etag).to eq "foo"
    end

    it "provides a last_modified accessor" do
      feed = @klass.new
      time = Time.now
      feed.last_modified = time
      expect(feed.last_modified).to eq time
      expect(feed.last_modified.class).to eq Time
    end

    it "returns new_entries? as true when entries are put into new_entries" do
      feed = @klass.new
      feed.new_entries << :foo
      expect(feed.new_entries?).to be true
    end

    it "returns a last_modified value from the entry with the most recent published date if the last_modified date hasn't been set" do
      feed = Feedjira::Parser::Atom.new
      entry = Feedjira::Parser::AtomEntry.new
      entry.published = Time.now.to_s
      feed.entries << entry
      expect(feed.last_modified).to eq entry.published
    end

    it "does not throw an error if one of the entries has published date of nil" do
      feed = Feedjira::Parser::Atom.new
      entry = Feedjira::Parser::AtomEntry.new
      entry.published = Time.now.to_s
      feed.entries << entry
      feed.entries << Feedjira::Parser::AtomEntry.new
      expect(feed.last_modified).to eq entry.published
    end
  end

  describe "#update_from_feed" do
    describe "updating feed attributes" do
      before do
        # I'm using the Atom class when I know I should be using a different
        # one. However, this update_from_feed method would only be called
        # against a feed item.
        @feed = Feedjira::Parser::Atom.new
        @feed.title    = "A title"
        @feed.url      = "http://pauldix.net"
        @feed.feed_url = "http://feeds.feedburner.com/PaulDixExplainsNothing"
        @feed.updated  = false
        @updated_feed = @feed.dup
      end

      it "updates the title if changed" do
        @updated_feed.title = "new title"
        @feed.update_from_feed(@updated_feed)

        expect(@feed.title).to eq @updated_feed.title
        expect(@feed).to be_updated
      end

      it "does not update the title if the same" do
        @feed.update_from_feed(@updated_feed)
        expect(@feed).not_to be_updated
      end

      it "updates the feed_url if changed" do
        @updated_feed.feed_url = "a new feed url"
        @feed.update_from_feed(@updated_feed)
        expect(@feed.feed_url).to eq @updated_feed.feed_url
        expect(@feed).to be_updated
      end

      it "updates the url if changed" do
        @updated_feed.url = "a new url"
        @feed.update_from_feed(@updated_feed)
        expect(@feed.url).to eq @updated_feed.url
      end

      it "does not update the url if not changed" do
        @feed.update_from_feed(@updated_feed)
        expect(@feed).not_to be_updated
      end
    end

    describe "updating entries" do
      before do
        # I'm using the Atom class when I know I should be using a different
        # one. However, this update_from_feed method would only be called
        # against a feed item.
        @feed = Feedjira::Parser::Atom.new
        @feed.title    = "A title"
        @feed.url      = "http://pauldix.net"
        @feed.feed_url = "http://feeds.feedburner.com/PaulDixExplainsNothing"
        @feed.updated  = false
        @updated_feed = @feed.dup
        @old_entry = Feedjira::Parser::AtomEntry.new
        @old_entry.url = "http://pauldix.net/old.html"
        @old_entry.published = Time.now.to_s
        @old_entry.entry_id = "entry_id_old"
        @new_entry = Feedjira::Parser::AtomEntry.new
        @new_entry.url = "http://pauldix.net/new.html"
        @new_entry.published = (Time.now + 10).to_s
        @new_entry.entry_id = "entry_id_new"
        @feed.entries << @old_entry
        @updated_feed.entries << @new_entry
        @updated_feed.entries << @old_entry
      end

      it "updates last-modified from the latest entry date" do
        @feed.update_from_feed(@updated_feed)
        expect(@feed.last_modified).to eq @new_entry.published
      end

      it "puts new entries into new_entries" do
        @feed.update_from_feed(@updated_feed)
        expect(@feed.new_entries).to eq [@new_entry]
      end

      it "alsoes put new entries into the entries collection" do
        @feed.update_from_feed(@updated_feed)
        expect(@feed.entries).to include(@new_entry)
        expect(@feed.entries).to include(@old_entry)
      end
    end

    describe "#update_from_feed" do
      let(:recent_entry_id) { "entry_id" }
      let(:old_entry_id) { nil }

      before do
        # I'm using the Atom class when I know I should be using a different
        # one. However, this update_from_feed method would only be called
        # against a feed item.
        @feed = Feedjira::Parser::Atom.new
        @feed.title    = "A title"
        @feed.url      = "http://pauldix.net"
        @feed.feed_url = "http://feeds.feedburner.com/PaulDixExplainsNothing"
        @feed.updated  = false
        @updated_feed = @feed.dup

        @old_entry = Feedjira::Parser::AtomEntry.new
        @old_entry.url = "http://pauldix.net/old.html"
        @old_entry.entry_id = old_entry_id
        @old_entry.published = (Time.now - 10).to_s

        @entry = Feedjira::Parser::AtomEntry.new
        @entry.published = (Time.now + 10).to_s
        @entry.entry_id = recent_entry_id
        @entry.url = "http://pauldix.net/entry.html"

        # only difference is a changed url
        @entry_changed_url = @entry.dup
        @entry_changed_url.url = "http://pauldix.net/updated.html"

        # entry with changed url must be first
        @feed.entries << @entry
        @feed.entries << @old_entry
        @updated_feed.entries << @entry_changed_url
        @updated_feed.entries << @old_entry
      end

      context "when changing the url of an existing entry" do
        it "does not put the complete feed into new_entries" do
          @feed.update_from_feed(@updated_feed)
          expect(@feed.new_entries).not_to include(@entry_changed_url)
          expect(@feed.new_entries).not_to include(@old_entry)
          expect(@feed.new_entries.size).to eq 0
          expect(@feed.new_entries.size).not_to eq 2
        end
      end

      context "when feed does not have entry id and only difference is a url" do
        let(:recent_entry_id) { nil }
        let(:old_entry_id) { nil }

        it "puts the complete feed into new_entries" do
          @feed.update_from_feed(@updated_feed)
          expect(@feed.new_entries).to include(@entry_changed_url)
          expect(@feed.new_entries).to include(@old_entry)
          expect(@feed.new_entries.size).to eq 2
          expect(@feed.new_entries.size).not_to eq 0
        end
      end
    end

    describe "updating with a feed" do
      let(:id_one) { "1" }
      let(:id_two) { "2" }

      let(:url_one) { "http://example.com/post_one.html" }
      let(:url_two) { "http://example.com/post_two.html" }

      let(:entry_one) { object_double(Feedjira::Parser::AtomEntry.new, entry_id: id_one, url: url_one) }

      let(:entry_two) { object_double(Feedjira::Parser::AtomEntry.new, entry_id: id_two, url: url_two) }

      let(:feed_one) { Feedjira::Parser::Atom.new }
      let(:feed_two) { object_double(Feedjira::Parser::Atom.new, entries: [entry_two]) }

      before do
        stub_const("Feedjira::FeedUtilities::UPDATABLE_ATTRIBUTES", [])
        feed_one.entries << entry_one
      end

      it "finds entries with unique ids and urls" do
        feed_one.update_from_feed feed_two
        expect(feed_one.new_entries).to eq [entry_two]
      end

      context "when the entries have the same id" do
        let(:id_two) { id_one }

        it "does not find a new entry" do
          feed_one.update_from_feed feed_two
          expect(feed_one.new_entries).to eq []
        end
      end

      context "when the entries have the same url" do
        let(:url_two) { url_one }

        it "does not find a new entry" do
          feed_one.update_from_feed feed_two
          expect(feed_one.new_entries).to eq []
        end
      end
    end
  end
end
