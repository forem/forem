# frozen_string_literal: true

require "spec_helper"

module Feedjira
  module Parser
    describe ".able_to_parser?" do
      it "returns true for Google Docs feed" do
        expect(GoogleDocsAtom).to be_able_to_parse(sample_google_docs_list_feed)
      end

      it "is not able to parse another Atom feed" do
        expect(GoogleDocsAtom).not_to be_able_to_parse(sample_atom_feed)
      end
    end

    describe "parsing" do
      before do
        @feed = GoogleDocsAtom.parse(sample_google_docs_list_feed)
      end

      it "returns a bunch of objects" do
        expect(@feed.entries).not_to be_empty
      end

      it "populates a title, interhited from the Atom entry" do
        expect(@feed.title).not_to be_nil
      end

      it "returns a bunch of entries of type GoogleDocsAtomEntry" do
        expect(@feed.entries.first).to be_a GoogleDocsAtomEntry
      end
    end
  end
end
