# frozen_string_literal: true

require "spec_helper"

describe Feedjira::Parser::GoogleDocsAtomEntry do
  describe "parsing" do
    before do
      xml = sample_google_docs_list_feed
      @feed = Feedjira::Parser::GoogleDocsAtom.parse xml
      @entry = @feed.entries.first
    end

    it "has the custom checksum element" do
      expect(@entry.checksum).to eq "2b01142f7481c7b056c4b410d28f33cf"
    end

    it "has the custom filename element" do
      expect(@entry.original_filename).to eq "MyFile.pdf"
    end

    it "has the custom suggested filename element" do
      expect(@entry.suggested_filename).to eq "TaxDocument.pdf"
    end
  end
end
